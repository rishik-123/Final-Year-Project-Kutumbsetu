import os

# Priority Core Architecture Files with second +10 pages allowance (Target: ~2,400 - 2,450 lines / ~48-49 pages max)
ESSENTIAL_ARCHITECTURE_FILES = [
    # 1. Frontend Entry & Network Engine
    "lib/main.dart",
    "lib/api_config.dart",

    # 2. Routing & Navigation Engine
    "lib/routes/app_router.dart",

    # 3. State Management Providers (Auth & Directory Filtering Engine)
    "lib/providers/auth_provider.dart",
    "lib/providers/member_providers.dart",

    # 4. Domain Data Models
    "lib/models/user_model.dart",
    "lib/models/member_model.dart",

    # 5. Core Flagship UI Screen (Full Member Directory with Search, Filters & A-Z Scroller)
    "lib/screens/member_directory_screen.dart",

    # 6. Core Backend Database Schemas (The Architecture Data Layer)
    "backend/models/User.js",
    "backend/models/Member.js",
    "backend/models/MatrimonialProfile.js",
    "backend/models/Campaign.js",
    "backend/models/Post.js"
]

base_dir = os.path.dirname(os.path.abspath(__file__))
output_file = os.path.join(base_dir, "KUTUMBSETU_CORE_SOURCE_CODES_FOR_BLACKBOOK.txt")

total_lines = 0

with open(output_file, "w", encoding="utf-8") as out:
    for i, rel_path in enumerate(ESSENTIAL_ARCHITECTURE_FILES):
        full_path = os.path.join(base_dir, rel_path.replace("/", os.sep))
        if os.path.exists(full_path):
            with open(full_path, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read().rstrip()
                lines = len(content.splitlines())
                total_lines += lines + 2 # +2 for filename and newline
                
                # Format: ONLY file name on top, then pure un-shrunk code (no hashes, no banners)
                out.write(f"{rel_path}\n\n")
                out.write(content)
                if i < len(ESSENTIAL_ARCHITECTURE_FILES) - 1:
                    out.write("\n\n\n")
            print(f"Added: {rel_path} ({lines} lines)")
        else:
            print(f"Warning: File not found: {rel_path}")

print(f"\nTotal lines in output: {total_lines}")
estimated_pages = total_lines / 50
print(f"Estimated Black Book pages (at 50 lines/page): ~{estimated_pages:.1f} pages")
print(f"Successfully updated: {output_file}")
