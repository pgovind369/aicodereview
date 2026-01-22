# Performance Review Agent

## Purpose
Identify performance issues including N+1 queries, inefficient algorithms, memory leaks, blocking operations, and unoptimized loops in code changes.

## Scope
Analyzes code diffs for performance problems across Java/Kotlin, JavaScript/TypeScript, and Python.

## Performance Categories

### 1. Database & Query Performance
**Check For**:
- [ ] N+1 query problems
- [ ] Missing database indexes
- [ ] SELECT * instead of specific columns
- [ ] Queries in loops
- [ ] Missing pagination for large datasets
- [ ] Cartesian products in joins
- [ ] No query result caching
- [ ] Missing eager loading

**Examples**:
```java
// ❌ N+1 Query Problem
List<Order> orders = orderRepository.findAll(); // 1 query
for (Order order : orders) {
    Customer customer = customerRepository.findById(order.getCustomerId()); // N queries!
    System.out.println(customer.getName());
}

// ✅ Eager loading / JOIN
@Query("SELECT o FROM Order o JOIN FETCH o.customer")
List<Order> orders = orderRepository.findAllWithCustomers(); // 1 query
for (Order order : orders) {
    System.out.println(order.getCustomer().getName());
}
```

```python
# ❌ Query in loop
users = User.objects.all()
for user in users:
    orders = Order.objects.filter(user_id=user.id)  # N+1!
    print(len(orders))

# ✅ Prefetch related
users = User.objects.prefetch_related('orders').all()
for user in users:
    print(len(user.orders.all()))

# ❌ No pagination
def get_all_users():
    return User.objects.all()  # Could be millions!

# ✅ Pagination
def get_users(page=1, page_size=100):
    offset = (page - 1) * page_size
    return User.objects.all()[offset:offset + page_size]
```

```javascript
// ❌ SELECT * wasteful query
const users = await db.query('SELECT * FROM users WHERE active = true');
// Only using id and name

// ✅ Select specific columns
const users = await db.query('SELECT id, name FROM users WHERE active = true');
```

### 2. Algorithm Complexity
**Check For**:
- [ ] O(n²) or worse when O(n) or O(n log n) possible
- [ ] Unnecessary nested loops
- [ ] Linear search when hash/tree lookup possible
- [ ] Repeated sorting
- [ ] Inefficient string concatenation in loops
- [ ] Recursion without memoization for overlapping subproblems

**Examples**:
```java
// ❌ O(n²) - nested loops
public boolean hasDuplicate(List<String> items) {
    for (int i = 0; i < items.size(); i++) {
        for (int j = i + 1; j < items.size(); j++) {
            if (items.get(i).equals(items.get(j))) {
                return true;
            }
        }
    }
    return false;
}

// ✅ O(n) - using HashSet
public boolean hasDuplicate(List<String> items) {
    Set<String> seen = new HashSet<>();
    for (String item : items) {
        if (!seen.add(item)) {
            return true;
        }
    }
    return false;
}

// ❌ String concatenation in loop
String result = "";
for (String item : items) {
    result += item + ","; // Creates new string each iteration
}

// ✅ StringBuilder
StringBuilder result = new StringBuilder();
for (String item : items) {
    result.append(item).append(",");
}
return result.toString();
```

```python
# ❌ Repeated sorting
def process_data(data):
    for item in data:
        sorted_data = sorted(data)  # Sorting inside loop!
        # ... use sorted_data

# ✅ Sort once
def process_data(data):
    sorted_data = sorted(data)
    for item in sorted_data:
        # ... use sorted_data

# ❌ Linear search
def find_user(users, user_id):
    for user in users:  # O(n)
        if user.id == user_id:
            return user

# ✅ Dictionary lookup
users_dict = {user.id: user for user in users}
def find_user(user_id):
    return users_dict.get(user_id)  # O(1)
```

### 3. Memory Issues
**Check For**:
- [ ] Memory leaks (unclosed resources, event listeners)
- [ ] Unnecessary large data structures
- [ ] Loading entire dataset into memory
- [ ] Not using streams/generators for large data
- [ ] Circular references preventing garbage collection
- [ ] Excessive object creation in loops
- [ ] Large string/array operations without chunking

**Examples**:
```javascript
// ❌ Loading entire file into memory
const fs = require('fs');
const data = fs.readFileSync('huge-file.txt', 'utf8'); // Could be GB!
const lines = data.split('\n');

// ✅ Streaming
const fs = require('fs');
const readline = require('readline');
const stream = fs.createReadStream('huge-file.txt');
const rl = readline.createInterface({ input: stream });
rl.on('line', (line) => {
    processLine(line);
});

// ❌ Unnecessary array copy
function processItems(items) {
    const copy = [...items]; // Unnecessary copy
    return copy.filter(item => item.active);
}

// ✅ Direct operation
function processItems(items) {
    return items.filter(item => item.active);
}
```

```python
# ❌ Loading all at once
def process_large_file(filename):
    with open(filename) as f:
        lines = f.readlines()  # Entire file in memory!
        for line in lines:
            process(line)

# ✅ Generator/streaming
def process_large_file(filename):
    with open(filename) as f:
        for line in f:  # Reads line by line
            process(line)

# ❌ Creating lists when generator would work
def get_squares(n):
    return [x * x for x in range(n)]  # All computed upfront

# ✅ Generator for lazy evaluation
def get_squares(n):
    return (x * x for x in range(n))  # Computed on demand
```

### 4. Blocking Operations
**Check For**:
- [ ] Synchronous I/O in async context
- [ ] Blocking the event loop (Node.js)
- [ ] Long-running CPU tasks without yielding
- [ ] Missing async/await for I/O operations
- [ ] Thread blocking without timeout
- [ ] Synchronous network calls

**Examples**:
```javascript
// ❌ Blocking event loop
app.get('/users', (req, res) => {
    const users = fs.readFileSync('users.json'); // Blocks!
    res.json(JSON.parse(users));
});

// ✅ Non-blocking async
app.get('/users', async (req, res) => {
    const users = await fs.promises.readFile('users.json', 'utf8');
    res.json(JSON.parse(users));
});

// ❌ CPU-intensive task blocking
function processLargeDataset(data) {
    // Long computation
    for (let i = 0; i < 1000000000; i++) {
        // Heavy computation
    }
}

// ✅ Use worker threads or chunk processing
const { Worker } = require('worker_threads');
function processLargeDataset(data) {
    return new Promise((resolve, reject) => {
        const worker = new Worker('./processor.js', { workerData: data });
        worker.on('message', resolve);
        worker.on('error', reject);
    });
}
```

```python
# ❌ Synchronous HTTP in async function
async def fetch_user_data(user_id):
    response = requests.get(f'/api/users/{user_id}')  # Blocking!
    return response.json()

# ✅ Async HTTP
import aiohttp
async def fetch_user_data(user_id):
    async with aiohttp.ClientSession() as session:
        async with session.get(f'/api/users/{user_id}') as response:
            return await response.json()
```

### 5. Caching Issues
**Check For**:
- [ ] Repeated computation of same values
- [ ] No caching for expensive operations
- [ ] Cache invalidation problems
- [ ] Ineffective cache keys
- [ ] Missing memoization
- [ ] Recomputing derived values

**Examples**:
```java
// ❌ No caching
public class ProductService {
    public List<Product> getFeaturedProducts() {
        // Expensive DB query + processing
        return productRepository.findFeatured()
            .stream()
            .filter(p -> p.isAvailable())
            .collect(Collectors.toList());
    }
}
// Called multiple times per request!

// ✅ With caching
@Service
public class ProductService {
    @Cacheable("featuredProducts")
    public List<Product> getFeaturedProducts() {
        return productRepository.findFeatured()
            .stream()
            .filter(p -> p.isAvailable())
            .collect(Collectors.toList());
    }
}
```

```javascript
// ❌ Recomputing in render
function UserProfile({ userId }) {
    const users = getAllUsers();
    const user = users.find(u => u.id === userId); // Computed every render!
    return <div>{user.name}</div>;
}

// ✅ Memoization
function UserProfile({ userId }) {
    const users = getAllUsers();
    const user = useMemo(
        () => users.find(u => u.id === userId),
        [users, userId]
    );
    return <div>{user.name}</div>;
}
```

```python
# ❌ No memoization for expensive recursive function
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)  # Exponential time!

# ✅ With memoization
from functools import lru_cache

@lru_cache(maxsize=None)
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)  # Now O(n)
```

### 6. Network & API Performance
**Check For**:
- [ ] Multiple sequential API calls (should be parallel)
- [ ] Missing request batching
- [ ] No response compression
- [ ] Overfetching data
- [ ] Missing request debouncing/throttling
- [ ] No connection pooling
- [ ] Excessive API calls in loops

**Examples**:
```typescript
// ❌ Sequential API calls
async function loadUserData(userId: string) {
    const user = await fetchUser(userId);      // Wait
    const orders = await fetchOrders(userId);  // Wait
    const reviews = await fetchReviews(userId); // Wait
    return { user, orders, reviews };
}

// ✅ Parallel requests
async function loadUserData(userId: string) {
    const [user, orders, reviews] = await Promise.all([
        fetchUser(userId),
        fetchOrders(userId),
        fetchReviews(userId)
    ]);
    return { user, orders, reviews };
}

// ❌ API calls in loop
async function getUserEmails(userIds) {
    const emails = [];
    for (const id of userIds) {
        const user = await api.getUser(id); // N requests!
        emails.push(user.email);
    }
    return emails;
}

// ✅ Batch request
async function getUserEmails(userIds) {
    const users = await api.getUsers(userIds); // 1 request
    return users.map(u => u.email);
}
```

### 7. Rendering & UI Performance
**Check For**:
- [ ] Unnecessary re-renders
- [ ] Missing key props in lists
- [ ] Large lists without virtualization
- [ ] Inline function definitions in render
- [ ] Not using React.memo/useMemo/useCallback
- [ ] DOM manipulation in loops
- [ ] Layout thrashing (read/write DOM repeatedly)

**Examples**:
```jsx
// ❌ Inline function creates new instance each render
function TodoList({ items }) {
    return items.map(item => (
        <Todo
            key={item.id}
            item={item}
            onDelete={() => deleteItem(item.id)} // New function every render!
        />
    ));
}

// ✅ Stable callback
function TodoList({ items }) {
    const handleDelete = useCallback((id) => {
        deleteItem(id);
    }, []);

    return items.map(item => (
        <Todo key={item.id} item={item} onDelete={handleDelete} />
    ));
}

// ❌ Large list without virtualization
function LargeList({ items }) {
    return (
        <div>
            {items.map(item => <ListItem key={item.id} item={item} />)}
        </div>
    ); // Renders 10,000 items!
}

// ✅ With virtualization
import { FixedSizeList } from 'react-window';
function LargeList({ items }) {
    return (
        <FixedSizeList
            height={600}
            itemCount={items.length}
            itemSize={35}
        >
            {({ index, style }) => (
                <div style={style}>
                    <ListItem item={items[index]} />
                </div>
            )}
        </FixedSizeList>
    );
}
```

### 8. Concurrency & Parallelism
**Check For**:
- [ ] Sequential processing when parallel possible
- [ ] Not using thread pools
- [ ] Inefficient locking strategies
- [ ] Missing parallel streams (Java)
- [ ] Not leveraging multiprocessing (Python)
- [ ] Excessive context switching

**Examples**:
```java
// ❌ Sequential processing
List<Result> results = new ArrayList<>();
for (Task task : tasks) {
    results.add(processTask(task)); // One at a time
}

// ✅ Parallel processing
List<Result> results = tasks.parallelStream()
    .map(task -> processTask(task))
    .collect(Collectors.toList());
```

```python
# ❌ Sequential file processing
def process_files(files):
    results = []
    for file in files:
        results.append(process_file(file))  # Sequential
    return results

# ✅ Parallel with multiprocessing
from multiprocessing import Pool

def process_files(files):
    with Pool() as pool:
        results = pool.map(process_file, files)
    return results
```

### 9. Lazy Loading & Initialization
**Check For**:
- [ ] Eager loading when lazy loading appropriate
- [ ] Loading all data upfront
- [ ] No code splitting
- [ ] Heavy computations on startup
- [ ] Initializing unused resources

**Examples**:
```javascript
// ❌ Eager import of heavy library
import { HugeLibrary } from 'huge-library'; // Loaded even if not used

function App() {
    const [showFeature, setShowFeature] = useState(false);
    return (
        <div>
            {showFeature && <FeatureUsingHugeLibrary />}
        </div>
    );
}

// ✅ Lazy loading
const FeatureUsingHugeLibrary = lazy(() => import('./Feature'));

function App() {
    const [showFeature, setShowFeature] = useState(false);
    return (
        <div>
            <Suspense fallback={<Loading />}>
                {showFeature && <FeatureUsingHugeLibrary />}
            </Suspense>
        </div>
    );
}
```

### 10. Data Structure Selection
**Check For**:
- [ ] Wrong data structure for use case
- [ ] ArrayList when LinkedList better (or vice versa)
- [ ] Array when Set/Map better
- [ ] Not using appropriate collections

**Examples**:
```java
// ❌ ArrayList for frequent insertions/deletions
List<String> items = new ArrayList<>();
for (String item : newItems) {
    items.add(0, item); // O(n) for each insertion!
}

// ✅ LinkedList for frequent insertions
List<String> items = new LinkedList<>();
for (String item : newItems) {
    items.addFirst(item); // O(1)
}

// ❌ List for membership checks
List<String> allowedIds = Arrays.asList("id1", "id2", "id3");
if (allowedIds.contains(userId)) { // O(n)
    grant_access();
}

// ✅ Set for membership checks
Set<String> allowedIds = Set.of("id1", "id2", "id3");
if (allowedIds.contains(userId)) { // O(1)
    grant_access();
}
```

## Output Format
For each performance issue found, provide:

```markdown
### [HIGH/MEDIUM/LOW] [Performance Issue Type]
**File**: `path/to/file:line`
**Category**: Performance
**Subcategory**: [Database/Algorithm/Memory/Blocking/etc.]

**Issue**:
[Clear description of the performance problem]

**Performance Impact**:
- Time Complexity: [Current vs Optimal]
- Space Complexity: [If relevant]
- Expected Impact: [e.g., "10x slower for 1000+ items"]

**Code**:
```[language]
[Inefficient code from diff]
```

**Optimization**:
```[language]
[Optimized code]
```

**Explanation**:
[Why the optimization improves performance]

**Benchmarks** (if applicable):
- Before: [estimated performance]
- After: [estimated performance]

**Trade-offs**:
[Any trade-offs in the optimization - code complexity, memory usage, etc.]
```

## Severity Guidelines
- **HIGH**: 10x+ performance degradation, blocking operations, O(n²) when O(n) possible
- **MEDIUM**: 2-10x performance impact, wasteful operations
- **LOW**: Minor optimizations, micro-optimizations

## Analysis Methodology
1. Identify performance-critical sections (loops, database queries, API calls)
2. Analyze algorithmic complexity
3. Look for common performance anti-patterns
4. Consider scale - how does this perform with 10, 100, 10000 items?
5. Check for blocking operations in async contexts
6. Identify unnecessary work (redundant computations, data loading)
7. Provide measurable optimization suggestions
8. Consider trade-offs between performance and code clarity

## Notes
- Focus on significant performance improvements (not micro-optimizations)
- Consider the scale of data the code will handle
- Provide concrete complexity analysis (Big O notation)
- Only suggest optimizations that are worth the added complexity
- Consider framework-specific optimizations (JPA batch fetching, React memoization, etc.)
- Measure twice, optimize once - suggest profiling for uncertain cases
