# CSO Finance

CSO Finance is a mobile-first fund management application built for the Computer Studies Organization (CSO), a student organization. It provides a streamlined interface for treasurers and auditors to track incoming funds, manage budget allocations, log expenses, and generate professional financial summaries.

## Overview

This application serves as an initial personal project developed to explore and demonstrate clean UI design and professional Flutter architecture. It is designed as an offline-first, local-state solution with no external backend or database requirements.

## Features

### Access and Onboarding

- Splash screen with logo reveal on startup
- Role-based access with a login screen for Treasurer and Auditor selection

### Fund Management

- Central dashboard with real-time visibility of total funds
- Automated allocation of funds across eight categories upon deposit
- Full, timestamped history of all funding sources

### Expense Tracking

- Detailed logging of expenses against specific categories
- Smart validation that prevents entries when funds are insufficient and warns before a category reaches zero balance
- Visual progress tracking with per-category history, running balances, and animated progress bars

### Reporting and Personalization

- Shareable reports that generate printable summaries, savable as read-only PNG receipts
- Instant global switching between dark and light mode
- Consistent deep-navy-blue design system using custom, reusable UI components

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Dart |
| Framework | Flutter (Material 3) |

## Project Structure

```
cso_finance/
├── assets/
│   └── CSO.png
├── lib/
│   ├── theme/
│   │   └── app_theme.dart
│   ├── screens/
│   │   ├── splash.dart
│   │   ├── login.dart
│   │   ├── dashboard.dart
│   │   └── printed_view.dart
│   ├── auditing/
│   │   ├── audit_form.dart
│   │   └── audit_list.dart
│   ├── services/
│   │   └── finance_store.dart
│   └── main.dart
├── pubspec.yaml
└── README.md
```

## Getting Started

### Prerequisites

- Flutter SDK (stable channel)
- Dart SDK (bundled with Flutter)

### Installation

```bash
git clone https://github.com/<your-username>/cso-finance.git
cd cso-finance
flutter pub get
```

### Running Locally

```bash
flutter run
```

### Building for Production

```bash
flutter build apk      # Android
flutter build ios      # iOS
flutter build web      # Web
```

## License

This project is provided for personal and portfolio purposes. Update this section if a specific license applies.

## Contact

For inquiries, please reach out through the contact details listed on the portfolio site.