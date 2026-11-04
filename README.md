# Pocket Expenses - Flutter Expense Tracker

An offline Flutter expense tracker application developed for the Flutter Application Development Programme at **Kallam Haranadhareddy Institute of Technology (KHIT)**.

Built to fulfill all requirements of the project specification (GP 1 to GP 11) for the **Expense tracker** approved topic.

---

## 👥 Team Information

| S.No | Name | Roll Number / ID | Contribution / Role |
| :--- | :--- | :--- | :--- |
| 1 | Team Lead | 258X5A0520 | Architecture, State Management, UI & GitHub Actions |
| 2 | Member 2 | [Roll Number] | Add Expense Form, Validations & Category logic |
| 3 | Member 3 | [Roll Number] | Expense Details, SharedPreferences persistence & Tests |

---

## 📱 Features & GP Requirements Compliance

| Requirement ID | Requirement | Implementation Details |
| :--- | :--- | :--- |
| **GP 1** | Navigation & Screens | Home list, Add Expense form, Detail view, and Category Summary screen. All reachable via bottom navigation or taps. |
| **GP 2** | Real Data (Persistence) | Expenses are saved to the device storage via `SharedPreferences` in JSON format. Survives app restart. |
| **GP 3** | Four Screen States | Home screen handles **Loading** (spinner), **Error** (with retry button), **Empty** (no expenses banner), and **Data** (expense list). |
| **GP 4** | Validated Form | Form validates title (non-empty), amount (positive decimal number), category selection, and date picking. |
| **GP 5** | Detail View | Dedicated `ExpenseDetailScreen` displaying full breakdown: title, amount, category icon, date, notes, entry ID, and delete option. |
| **GP 6** | Shared State | Implemented using `ChangeNotifierProvider` and `ExpenseStore` across all screens. |
| **GP 7** | Consistent Theme | Material 3 theme generated with seed color `#176B5B` (Deep Teal), consistent cards, fonts, and icons. |
| **GP 8** | Robustness | Protected against empty inputs, long texts (`TextOverflow.ellipsis`), orientation changes, and invalid numbers. |
| **GP 9** | Repository | Hosted on GitHub with clean commits, structured workflow, and documentation. |
| **GP 10** | Release Build | Automated build via GitHub Actions producing `app-release.apk`. |
| **GP 11** | Widget Test | Verified with automated widget and unit tests using `flutter test`. |

---

## 🚀 Approved Topic Scope (4.3: Expense Tracker)

- ✅ **Add expenses** with amount, category, date, and note through a validated form.
- ✅ **List of expenses** with category icons, formatted date, and currency.
- ✅ **Expense Detail Screen** with complete information and deletion support.
- ✅ **Summary Screen with totals per category** and interactive progress indicators.
- ✅ **Offline persistence** using `SharedPreferences`.

---

## 💻 How to Run in VS Code

1. Open this folder in **VS Code**:
   ```sh
   code .
   ```
2. Ensure the Flutter extension is installed in VS Code.
3. Open terminal (**Ctrl + `**) and fetch dependencies:
   ```sh
   flutter pub get
   ```
4. Run tests:
   ```sh
   flutter test
   ```
5. Run the application:
   ```sh
   flutter run
   ```

---

## 📦 Building the Release APK

### Option A: Automatically via GitHub Actions (Recommended)
1. Push your code to GitHub.
2. Go to the **Actions** tab on your GitHub repository.
3. Once the build completes, download the **`pocket-expenses-release-apk`** artifact.

### Option B: Local Build
```sh
flutter build apk --release
```
The output file will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 🐛 Defect Log (Testing & Verification)

| Defect ID | Description | Steps to Reproduce | Resolution | Status |
| :--- | :--- | :--- | :--- | :--- |
| **DEF-01** | Negative/zero expense values allowed | Enter `0` or `-50` in Amount field and tap Save | Added strict regex / `double.tryParse` validation ensuring `amount > 0` | **Fixed** |
| **DEF-02** | Text overflow on long titles | Enter an expense title longer than 50 characters | Added `maxLines: 1` and `TextOverflow.ellipsis` | **Fixed** |
| **DEF-03** | Missing category breakdown screen | Topic 4.3 requires summary screen with category totals | Created dedicated `SummaryView` and added bottom navigation tab | **Fixed** |
| **DEF-04** | Missing widget test | Assignment GP 11 required widget test | Implemented `testWidgets` in `test/widget_test.dart` testing initial app render | **Fixed** |
| **DEF-05** | Top-level import syntax in `main.dart` | `import 'dart:convert';` placed at bottom of file | Moved all imports to the top of `lib/main.dart` | **Fixed** |
