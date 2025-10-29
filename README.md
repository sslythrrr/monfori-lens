# MonforiLens

A Flutter application designed to help users select, sort, rename, and share photos from their device gallery. The app allows for easy organization and batch processing of images.

---

## Key Features

* **Photo Selection**: Browse device albums and select multiple photos.
* **Photo Sorting**: Photos are initially sorted based on filename patterns (numerical extraction) and creation date.
* **Manual Reordering**: Drag and drop photos in a grid view to manually adjust the desired order.
* **Preview**: View selected photos and their order before processing.
* **Batch Renaming**: Automatically rename photos based on their final order, a unique device code (configurable), and creation timestamp (e.g., `[uniqueCode]_mf[orderNumber]_[dateTime].[ext]`).
* **Sharing**: Share processed photos individually or as a compressed ZIP folder.
* **Save Locally**: Option to save the processed (and compressed) photos to the device's storage.
* **Settings**: Configure the unique code used in file renaming.

---

## Technologies Used

* **Framework**: Flutter
* **Language**: Dart
* **Key Packages**:
    * `photo_manager`: Accessing and managing device photos/albums.
    * `reorderable_grid_view`: Enabling drag-and-drop reordering in the preview screen.
    * `share_plus`: Sharing files with other applications.
    * `archive`: Compressing files into a ZIP archive.
    * `path_provider`, `path`: Handling file system paths.
    * `device_info_plus`, `crypto`, `shared_preferences`: Generating and storing a unique device code.
    * `permission_handler`: Requesting necessary permissions (storage, photos).
    * `intl`: Formatting dates and numbers.
    * `google_fonts`: Custom fonts.
    * `camera`: Camera integration.

---

## Prerequisites

Before you begin, ensure you have the following installed on your system:

* **Flutter SDK**: (Check the required version in `pubspec.yaml`) - Installation guide at [flutter.dev](https://flutter.dev/docs/get-started/install)
* **Dart SDK**: (Comes bundled with Flutter)
* **Platform-specific tools**:
    * **Android**: Android Studio and Android SDK.
    * **iOS/macOS**: Xcode.
    * **Windows**: Visual Studio with "Desktop development with C++" workload.
    * **Linux**: C++ compiler, GTK development headers, Clang, CMake.

---

## Installation and Setup

1.  **Clone the repository**:
    ```bash
    git clone [https://github.com/your-username/monforilens.git](https://github.com/your-username/monforilens.git)
    cd monforilens
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Run the application**:
    * Connect a device or start an emulator/simulator.
    * Run the app using the Flutter CLI:
        ```bash
        flutter run
        ```

---

## Example Usage

1.  Launch the MonforiLens application.
2.  Tap the "Mulai" (Start) button on the home screen.
3.  Browse your photo library ("Semua Foto" tab) or specific albums ("Album" tab).
4.  Tap photos to select them. Use "Pilih Semua" (Select All) or "Batalkan Pilih" (Deselect All) as needed.
5.  Once photos are selected, tap the "Proses" (Process) button.
6.  On the "Penyesuaian Akhir" (Final Adjustment) screen, drag and drop photos to reorder them as desired.
7.  Tap "Konfirmasi" (Confirm). The app will process (copy and rename) the photos.
8.  On the "Hasil Akhir" (Final Result) screen, you can:
    * Modify the suggested folder name (used for the ZIP file).
    * Tap "Bagikan" (Share) to share the compressed ZIP folder.
    * Tap "Simpan ke Lokal" (Save to Local) to save the ZIP file to your device's Downloads folder (Android).
9.  Optionally, use the Settings screen (accessible from the home screen) to change the unique code used for renaming files.

---

## Contributing

Contributions are welcome! If you'd like to contribute, please follow these steps:

1.  **Fork** the repository on GitHub.
2.  **Clone** your forked repository to your local machine.
3.  Create a new **branch** for your feature or bug fix (`git checkout -b feature/your-feature-name`).
4.  Make your changes and **commit** them (`git commit -m 'Add some feature'`).
5.  **Push** your changes to your fork on GitHub (`git push origin feature/your-feature-name`).
6.  Open a **Pull Request** from your fork to the original repository.

Please ensure your code follows the project's coding style (consider running `flutter analyze` and `dart format .`) and includes relevant tests if applicable.

---

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.
