# Movie Diary — Team Development Guide & Collaboration Protocol

> **Target Audience:** Team of 3 beginners (Long, Doan, Tai)  
> **Course:** PRM393 — Mobile Programming  
> **Duration:** 1 Week (7 Days)  
> **App:** Movie Diary (Personal Movie Tracker with CRUD)

---

## 1. Project Directory & File Responsibilities

The project follows a clean, feature-driven folder structure inside `lib/` to keep our codebase decoupled and allow all 3 members to work simultaneously without merge conflicts:

```
lib/
├── app.dart                                # Root MaterialApp widget & global theme configuration
├── main.dart                               # Application entry point (main() function)
├── models/
│   └── movie.dart                          # Shared Movie data class with SQLite serialization
├── database/
│   └── database_helper.dart                # Singleton SQLite helper for database initialization & CRUD
├── utils/
│   └── constants.dart                      # Common constants (table/column names, colors, genres)
├── widgets/
│   └── movie_card.dart                     # Reusable movie card component for lists and grids
└── features/
    ├── library/
    │   └── library_screen.dart             # Main screen with movie browse, search, and filter UI
    ├── movie_form/
    │   └── movie_form_screen.dart          # Form screen for creating and editing movie entries
    ├── movie_detail/
    │   └── movie_detail_screen.dart        # Screen showing full movie information, actions, and reviews
    ├── watchlist/
    │   └── watchlist_screen.dart           # Dedicated screen showing unwatched / plan-to-watch movies
    └── statistics/
        └── statistics_screen.dart          # Screen presenting summary metrics (total watched, ratings, genres)
```

### Detailed Purpose of Each File

- **`lib/main.dart`**: The app launch pad. Calls `WidgetsFlutterBinding.ensureInitialized()` and runs `MovieDiaryApp`.
- **`lib/app.dart`**: Sets up `MaterialApp`, defining app theme (colors, fonts), routes, and the home screen.
- **`lib/models/movie.dart`**: The single source of truth for movie data. Maps between Dart objects and SQLite rows via `toMap()` and `fromMap()`.
- **`lib/database/database_helper.dart`**: Manages the SQLite database file (`movie_diary.db`), creates the `movies` table, and exposes typed Future-based CRUD methods (`insertMovie`, `getAllMovies`, `updateMovie`, `deleteMovie`, etc.).
- **`lib/utils/constants.dart`**: Contains database table/column name constants, predefined movie genres (e.g., Action, Comedy, Drama, Sci-Fi, Horror, Romance, Animation), and theme styling constants.
- **`lib/widgets/movie_card.dart`**: Reusable widget used in both the Library and Watchlist screens to display movie cover placeholder, title, release year, rating badge, and genre chip.
- **`lib/features/library/library_screen.dart`**: The default home screen where users can browse all movies, search by title or director, and filter by genre or watch status. Includes a FloatingActionButton (FAB) to add movies.
- **`lib/features/movie_form/movie_form_screen.dart`**: Handles both adding a new movie and editing an existing one. Contains form validation (ensuring title is not empty, valid release year, valid rating).
- **`lib/features/movie_detail/movie_detail_screen.dart`**: Shows complete details: full title, director, release year, genre, star rating, personal review, date watched, and a toggle for watch status. Includes Edit and Delete action buttons.
- **`lib/features/watchlist/watchlist_screen.dart`**: Lists only movies that have `isWatched == false`, with quick action to mark as watched.
- **`lib/features/statistics/statistics_screen.dart`**: Computes and displays aggregate metrics: total movies logged, number watched vs. in watchlist, average rating, and top genres.

---

## 2. Beginner-Friendly Coding Rules

To maintain high code quality and prevent common beginner mistakes:

1. **Use `const` Constructors Liberally**:
   - Always add `const` to widgets that do not change dynamically (e.g., `const SizedBox(height: 16)`). This improves performance and satisfies `flutter_lints`.

2. **Null Safety First**:
   - Every field must either be non-nullable with a default value or explicitly marked nullable (`?`).
   - Only `id` and `review` should be nullable in our model. All other fields have safe defaults.

3. **Stateless vs. Stateful**:
   - Start with `StatelessWidget`. Only convert to `StatefulWidget` when the widget needs internal mutable state (e.g., `TextEditingController`, form validation, toggles, filter selections).

4. **Async/Await & Error Handling**:
   - Always wrap database calls in `try / catch` blocks.
   - Show user-friendly feedback on failure using `ScaffoldMessenger.of(context).showSnackBar(...)`.

5. **No Magic Strings or Numbers**:
   - Do not write raw SQL column names like `'title'` in screens; reference `Constants.colTitle` or keys defined in `Movie`.
   - Predefine genres in `Constants.movieGenres` to avoid typos.

6. **Naming Conventions**:
   - **Classes / Types**: `PascalCase` (`Movie`, `DatabaseHelper`, `MovieCard`).
   - **Files / Folders**: `snake_case` (`movie_card.dart`, `library_screen.dart`).
   - **Variables / Functions**: `camelCase` (`getAllMovies()`, `isWatched`, `movieList`).
   - **Constants**: `lowerCamelCase` or `kPascalCase` (`dbName`, `kPrimaryColor`).

7. **Clean Imports**:
   - Avoid messy relative parent imports (`../../`). Prefer consistent package imports (e.g., `import 'package:movie/models/movie.dart';`) or tidy local folder imports.

---

## 3. Shared `Movie` Model Schema & Database Contract

> **CRITICAL:** All team members must adhere strictly to these exact property names, types, and method signatures so everyone's code plugs together seamlessly.

### `Movie` Model Contract (`lib/models/movie.dart`)

```dart
class Movie {
  final int? id;             // Auto-increment primary key in SQLite (null before insertion)
  final String title;        // Required, cannot be blank
  final String director;     // Director name (default empty string if omitted)
  final int releaseYear;     // e.g. 2024
  final String genre;        // e.g. "Action", "Drama", "Sci-Fi"
  final double rating;       // Rating from 0.0 to 5.0 stars
  final bool isWatched;      // true: watched; false: in watchlist / plan-to-watch
  final String? review;      // Optional personal review / thoughts
  final String watchedDate;  // ISO date string 'YYYY-MM-DD' or timestamp

  Movie({
    this.id,
    required this.title,
    this.director = '',
    required this.releaseYear,
    required this.genre,
    this.rating = 0.0,
    this.isWatched = false,
    this.review,
    this.watchedDate = '',
  });

  // Convert Movie object to Map for SQLite insert/update
  Map<String, dynamic> toMap();

  // Construct Movie object from SQLite row Map
  factory Movie.fromMap(Map<String, dynamic> map);

  // Helper method for updating fields immutably
  Movie copyWith({
    int? id,
    String? title,
    String? director,
    int? releaseYear,
    String? genre,
    double? rating,
    bool? isWatched,
    String? review,
    String? watchedDate,
  });
}
```

### SQLite Schema (`lib/database/database_helper.dart`)

- **Database File:** `movie_diary.db`
- **Table Name:** `movies`
- **SQL Table Creation:**
  ```sql
  CREATE TABLE movies (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    director TEXT,
    release_year INTEGER NOT NULL,
    genre TEXT NOT NULL,
    rating REAL NOT NULL DEFAULT 0.0,
    is_watched INTEGER NOT NULL DEFAULT 0,
    review TEXT,
    watched_date TEXT
  );
  ```
  *(Note: SQLite stores booleans as integers: `0` for false, `1` for true).*

### `DatabaseHelper` Method Signatures

```dart
class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  Future<Database> get database;

  // CREATE
  Future<int> insertMovie(Movie movie);

  // READ
  Future<List<Movie>> getAllMovies();
  Future<Movie?> getMovieById(int id);
  Future<List<Movie>> getWatchlistMovies(); // where is_watched == 0
  Future<List<Movie>> getWatchedMovies();   // where is_watched == 1
  Future<List<Movie>> searchMovies(String query); // matches title or director
  Future<List<Movie>> getMoviesByGenre(String genre);

  // UPDATE
  Future<int> updateMovie(Movie movie);

  // DELETE
  Future<int> deleteMovie(int id);
}
```

---

## 4. Task Division & Individual Responsibilities

### **Member 1: Long** — Library & Discovery UI
- **Files Owned:**
  - `lib/widgets/movie_card.dart`
  - `lib/features/library/library_screen.dart`
  - Contributing to `lib/utils/constants.dart` (color schemes & styles)
- **Key Responsibilities:**
  - Design the `MovieCard` widget (poster placeholder icon, title, year, genre pill, star rating).
  - Build `LibraryScreen` displaying the list of all movies retrieved from `DatabaseHelper`.
  - Implement a real-time `TextField` search bar filtering by movie title or director.
  - Implement horizontal genre filter chips (All, Action, Comedy, Drama, Sci-Fi, etc.).
  - Add floating action button (FAB) that navigates to the Add Movie Form.
  - Implement empty state UI when no movies are logged or search returns empty.

### **Member 2: Doan** — Data Layer & Input Management
- **Files Owned:**
  - `lib/models/movie.dart`
  - `lib/database/database_helper.dart`
  - `lib/features/movie_form/movie_form_screen.dart`
- **Key Responsibilities:**
  - Implement the `Movie` model with `toMap()`, `fromMap()`, and `copyWith()`.
  - Set up SQLite using `sqflite` and `path`, implementing database creation and all required CRUD methods in `DatabaseHelper`.
  - Build `MovieFormScreen` serving both "Add Movie" and "Edit Movie" modes.
  - Implement Form validation:
    - Title must not be empty.
    - Release year must be a valid 4-digit number.
    - Rating must be between 0.0 and 5.0.
  - Form UI inputs: Title, Director, Release Year, Genre Dropdown, Rating selector, Watched checkbox, and Review text area.
  - Handle saving to SQLite and returning the result to refresh previous screens.

### **Member 3: Tai** — Details, Watchlist, Analytics & Testing
- **Files Owned:**
  - `lib/features/movie_detail/movie_detail_screen.dart`
  - `lib/features/watchlist/watchlist_screen.dart`
  - `lib/features/statistics/statistics_screen.dart`
  - Quality assurance and Integration verification
- **Key Responsibilities:**
  - Build `MovieDetailScreen` displaying full movie information, user review notes, and watched date.
  - Implement quick "Toggle Watched / Watchlist" button on detail screen updating database state.
  - Implement Delete button with confirmation modal dialog (`showDialog`) to prevent accidental deletion.
  - Provide Edit button on detail screen navigating to `MovieFormScreen` in edit mode.
  - Build `WatchlistScreen` listing only unwatched movies (`isWatched == false`).
  - Build `StatisticsScreen` showing: total movies logged, watched count, watchlist count, average user rating, and favorite genre breakdown.
  - Execute end-to-end integration tests using the CRUD checklist.

---

## 5. 7-Day Development Schedule

| Day | Focus / Milestone | Long's Tasks | Doan's Tasks | Tai's Tasks |
| :--- | :--- | :--- | :--- | :--- |
| **Day 1** | **Setup & Foundation** | Review structure, design UI layout drafts for Library | Implement `Movie` model (`fromMap`, `toMap`) | Design wireframes for Detail & Watchlist screens |
| **Day 2** | **Core Database & Cards** | Build reusable `MovieCard` widget with mock data | Implement `DatabaseHelper` (DB init, `insert`, `getAll`) | Scaffold `MovieDetailScreen` UI with mock data |
| **Day 3** | **Read & Form Scaffold** | Connect `LibraryScreen` to `DatabaseHelper.getAllMovies()` | Build `MovieFormScreen` UI with form fields and validation | Scaffold `WatchlistScreen` and `StatisticsScreen` |
| **Day 4** | **Create & Filter Features** | Add search bar and genre filter chips to Library | Connect `MovieFormScreen` to `DatabaseHelper.insertMovie()` | Connect `WatchlistScreen` to `DatabaseHelper.getWatchlistMovies()` |
| **Day 5** | **Update & Delete (UD)** | Refine Library animations, pull-to-refresh & empty states | Add edit mode to `MovieFormScreen` with `updateMovie()` | Connect Detail screen to `updateMovie` (status toggle) & `deleteMovie` (dialog) |
| **Day 6** | **Integration & Stats** | Polish main navigation (BottomNavigationBar or Drawer) | Verify DB constraints, test error handling & data safety | Wire `StatisticsScreen` calculations with live DB data; run end-to-end testing |
| **Day 7** | **Testing & Final Demo** | UI theme cleanup, icons, contrast fixes | Final code review, database backup/reset helper | Run full CRUD checklist, fix any remaining bugs, prepare presentation |

---

## 6. Git Branching & Collaboration Workflow

### Branch Strategy
- **`main`**: Production-ready branch. Never commit or push directly to `main`!
- **`dev`**: Main development and integration branch.
- **Feature Branches**:
  - `feature/long-library`
  - `feature/doan-database-form`
  - `feature/tai-detail-stats`

### Step-by-Step Daily Git Routine

1. **Before starting work each day, pull the latest updates:**
   ```bash
   git checkout dev
   git pull origin dev
   ```

2. **Work on your feature branch:**
   ```bash
   git checkout -b feature/your-name-feature
   # Or switch if it already exists:
   git checkout feature/your-name-feature
   git merge dev
   ```

3. **Make small, focused commits with meaningful messages:**
   ```bash
   git add .
   git commit -m "feat(library): implement movie card layout with rating stars"
   ```

4. **Run static analysis before pushing code:**
   ```bash
   flutter analyze
   flutter test
   ```

5. **Push and create a Pull Request (PR):**
   ```bash
   git push origin feature/your-name-feature
   ```
   - Open a PR into `dev`.
   - Have at least one other team member review and approve before merging.

---

## 7. CRUD Testing Checklist

Before submitting the assignment, verify every single item below on an emulator or physical device:

### 1. Create (Add Movie)
- [ ] Tapping the Floating Action Button (+) opens the Add Movie form.
- [ ] Attempting to submit without a title triggers an inline validation error.
- [ ] Successfully adding a movie with full information (title, director, year, genre, rating, review, watched status).
- [ ] Successfully adding a movie with only required information (title, year, genre).
- [ ] After saving, form closes and the new movie appears immediately in the Library without manual reload.
- [ ] When saving with `isWatched = false`, the movie appears in the Watchlist.

### 2. Read (Browse, Search, Filter)
- [ ] Library displays all movies from the SQLite database.
- [ ] Typing in the search bar filters movies dynamically by title or director.
- [ ] Selecting a genre chip filters the movie list accordingly.
- [ ] Selecting "All" resets the genre filter.
- [ ] An appropriate "No movies found" message displays if search or filter yields no results.
- [ ] Tapping any movie card opens `MovieDetailScreen` with accurate information.
- [ ] Watchlist displays only movies where `isWatched == false`.
- [ ] Statistics screen accurately reflects:
  - [ ] Total movies count.
  - [ ] Watched count vs Watchlist count.
  - [ ] Correct average rating calculation.
  - [ ] Most frequent genre.

### 3. Update (Edit Movie & Toggle Status)
- [ ] Tapping the "Edit" button on `MovieDetailScreen` opens the form populated with existing movie data.
- [ ] Modifying fields (e.g., updating rating or review) and clicking "Update" saves changes.
- [ ] Detail screen immediately shows the updated details upon returning.
- [ ] Library screen shows updated data when navigating back.
- [ ] Toggling the "Watched" checkbox/button in the Detail screen switches `isWatched` status and updates SQLite.
- [ ] Marking a watchlist item as watched removes it from Watchlist and increases the watched counter in Statistics.

### 4. Delete (Remove Movie)
- [ ] Tapping the "Delete" button on `MovieDetailScreen` displays a confirmation dialog.
- [ ] Tapping "Cancel" closes the dialog without deleting the movie.
- [ ] Tapping "Confirm Delete" removes the movie from SQLite.
- [ ] App returns to previous screen gracefully.
- [ ] Deleted movie is no longer present in Library, Watchlist, or Statistics.

### 5. Persistence & Edge Cases
- [ ] Fully close (kill) the app and restart it. All added, updated, and deleted changes remain intact.
- [ ] App handles long text strings in title, director, and review without UI overflow errors (yellow/black stripes).
- [ ] Rapid tapping on Save / Delete does not create duplicate entries or cause crashes.

