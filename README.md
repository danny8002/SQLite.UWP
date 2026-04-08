# SQLite Library for Universal Windows Platform (UWP)

[![NuGet Package](https://img.shields.io/nuget/v/SQLite.Universal.svg)](https://www.nuget.org/packages/SQLite3.Universal/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive SQLite library for Universal Windows Platform (UWP) applications, providing native SQLite support for **x86**, **x64**, **ARM**, and **ARM64** architectures.

## 🎯 Why This Package?

**Replace Visual Studio SQLite Extension** - This NuGet package is designed as a **drop-in replacement** for the [SQLite for Universal Windows Platform](https://marketplace.visualstudio.com/items?itemName=SQLiteDevelopmentTeam.SQLiteforUniversalWindowsPlatform) Visual Studio extension.

### ✅ Advantages Over VS Extension:

- 🚫 **No Extension Installation Required** - Works immediately after NuGet package installation
- 🔄 **Easier CI/CD Integration** - No need to install extensions on build servers
- 📦 **Project-Level Dependency** - SQLite version managed per project, not globally
- 🔧 **Simplified Setup** - No manual reference management or project configuration
- 🏗️ **Better Build Reliability** - Eliminates extension dependency issues in automated builds
- 👥 **Team-Friendly** - All team members get the same SQLite version automatically

### 🔄 Migration from VS Extension:

If you're currently using the Visual Studio SQLite extension:

1. **Uninstall the extension** (optional, but recommended to avoid conflicts)
2. **Remove SQLite references** from your project
3. **Install this NuGet package**: `Install-Package SQLite3.Universal`
4. **Rebuild your project** - that's it!

No code changes required - your existing SQLite code will work unchanged.

## ✨ Features

- 🚀 **Multi-Architecture Support**: Native binaries for x86, x64, ARM, and ARM64
- 📦 **Easy Integration**: Simple NuGet package installation - **replaces VS SQLite extension**
- 🔧 **No Extension Required**: Works without Visual Studio SQLite extension dependency
- 🏗️ **Build-Ready**: Automatic file copying to output directory
- ⚡ **High Performance**: Native SQLite implementation
- 🔒 **Thread-Safe**: Full mutex and shared cache support
- 🚫 **CI/CD Friendly**: No extension installation needed on build servers

## 🚀 Quick Start

### Basic Usage Example

```csharp
using SQLite;
using System.IO;
using Windows.Storage;

// Define your data model
public class Person
{
    [PrimaryKey, AutoIncrement]
    public int Id { get; set; }
    
    [MaxLength(50)]
    public string Name { get; set; }
    
    public int Age { get; set; }
}

// Initialize database connection
var databasePath = Path.Combine(ApplicationData.Current.LocalFolder.Path, "MyDatabase.db");
var connection = new SQLiteConnection(databasePath);

// Create table
connection.CreateTable<Person>();

// Insert data
var person = new Person { Name = "John Doe", Age = 30 };
connection.Insert(person);

// Query data
var people = connection.Table<Person>().Where(p => p.Age > 25).ToList();
```

### Advanced Connection Setup

```csharp
var connectionString = new SQLiteConnectionString(
    databasePath, 
    false  // storeDateTimeAsTicks
);

var connection = new SQLiteConnectionWithLock(
    connectionString,
    SQLiteOpenFlags.ReadWrite | 
    SQLiteOpenFlags.Create | 
    SQLiteOpenFlags.FullMutex | 
    SQLiteOpenFlags.SharedCache
);
```

## 🏗️ Building from Source

### Prerequisites

- Visual Studio 2017 or later
- Windows 10 SDK
- UWP development workload

### Build Steps

1. **Clone the repository**:
   ```bash
   git clone https://github.com/danny8002/SQLite3.Universal.git
   cd SQLite3.Universal
   ```

2. **Open the solution**:
   ```bash
   start SQLite3.Universal.sln
   ```

3. **Build for all platforms**:
   - Set solution configuration to `Release`
   - Build for `x86`, `x64`, `ARM`, and `ARM64` platforms
   - Output files will be in `Build/{Platform}/Release/`

4. **Package NuGet** (optional):
   ```bash
   cd NuGet
   nuget.exe pack package.nuspec
   ```

## 🔄 Upgrading SQLite Version

Run the [`update.ps1`](update.ps1) script to automatically upgrade to the latest SQLite version:

```powershell
.\update.ps1
```

The script performs the following steps:

1. **Detects the latest version** from the [SQLite Download Page](https://www.sqlite.org/download.html)
2. **Skips if already up-to-date** by comparing with the current version in [`NuGet/package.nuspec`](NuGet/package.nuspec)
3. **Downloads and extracts** the SQLite amalgamation zip
4. **Replaces source files** (`sqlite3.c`, `sqlite3.h`, `sqlite3ext.h`) in [`SQLite.Universal/SourceCode/`](SQLite.Universal/SourceCode/)
5. **Patches `sqlite3.c`** for UWP compatibility (guards `GetModuleHandleW` which is unavailable in `WINAPI_FAMILY_APP`)
6. **Updates version** in [`NuGet/package.nuspec`](NuGet/package.nuspec) and [`sqlite3rc.h`](SQLite.Universal/SourceCode/sqlite3rc.h)
7. **Builds all platforms** (ARM, ARM64, x64, x86) in Release configuration
8. **Packs the NuGet package** in the [`NuGet/`](NuGet/) directory

### Prerequisites

- `msbuild2` available on PATH (build wrapper script)
- `nuget` CLI available on PATH

### Version Verification

You can verify the SQLite version at runtime:

```csharp
var version = SQLite3.LibVersionNumber();
var versionString = SQLite3.LibVersion();
Console.WriteLine($"SQLite Version: {versionString} ({version})");
```

### 🔧 Troubleshooting Upgrades

**Build Errors**: Check for new compilation flags or dependencies in the new SQLite version.

**Runtime Issues**: Test thoroughly as newer SQLite versions may have behavioral changes.

**Compatibility**: Verify database files created with older versions still work.

## 📁 Project Structure

```
SQLite3.Universal/
├── SQLite.Universal/          # Main library project
│   ├── SourceCode/           # SQLite source files
│   │   ├── sqlite3.c         # SQLite implementation
│   │   ├── sqlite3.h         # Main header
│   │   └── sqlite3ext.h      # Extension header
│   └── SQLite.Universal.vcxproj
├── NuGet/                    # NuGet package configuration
│   ├── package.nuspec        # Package specification
│   └── uap10.0/              # Build properties
├── Samples/                  # Example applications
│   └── TestApplicationStorage/
└── README.md
```

## 📋 Requirements

- **Target Framework**: UWP (UAP 10.0 or later)
- **Supported Architectures**: x86, x64, ARM, ARM64
- **Minimum Windows Version**: Windows 10 version 1803 (Build 17134)
- **Development**: Visual Studio 2017 or later with UWP workload

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/danny8002/SQLite3.Universal/issues)
- **Documentation**: [SQLite.org Documentation](https://www.sqlite.org/docs.html)
- **NuGet**: [Package Page](https://www.nuget.org/packages/SQLite.Universal/)

## 🙏 Acknowledgments

- [SQLite Development Team](https://www.sqlite.org/crew.html) for the excellent database engine
- [sqlite-net](https://github.com/praeclarum/sqlite-net) for inspiration and ORM patterns
- UWP developer community for feedback and contributions

---

**Note**: This library provides the native SQLite binaries. For ORM functionality, consider using it with [sqlite-net-pcl](https://www.nuget.org/packages/sqlite-net-pcl/) or similar packages.
