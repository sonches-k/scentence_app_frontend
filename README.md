# Scentence

iOS-приложение для подбора парфюмерии по текстовым описаниям. Пользователь описывает желаемый аромат в свободной форме — система подбирает релевантные рекомендации, строит пирамиду нот и формирует объяснение через LLM.

## Возможности

- **Поиск на естественном языке** — произвольный текстовый запрос, LLM-ранжирование результатов
- **Выбор LLM-провайдера** — DeepSeek (через бэкенд) или Apple Intelligence (on-device, iOS 26+)
- **Фильтры** — семейство, пол, тип продукта, категория (Люкс / Нишевая / Восточная / Масляная), бренд, ноты, год выпуска
- **Карточка аромата** — пирамида нот, AI-описание (review summary), теги, похожие парфюмы, ссылка для покупки
- **Поделиться** — экспорт результатов подбора в виде изображения (запрос, фильтры, пирамида нот, топ-3 аромата)
- **Избранное и история поиска** — сохранение между сессиями, повтор запроса в один тап
- **Профиль** — аватар, имя, тема оформления (светлая/тёмная)
- **Аутентификация по email** — вход через одноразовый код, без паролей

## Требования

- iOS 17.0+ (Apple Intelligence — iOS 26+)
- Xcode 16+
- Запущенный экземпляр [бэкенда](https://github.com/sonches-k/scentence_app_backend)

## Быстрый старт

1. Клонируйте репозиторий и откройте `Scentence.xcodeproj` в Xcode.
2. Настройте URL бэкенда: `Product → Scheme → Edit Scheme → Run → Environment Variables`, добавьте `API_BASE_URL = http://<ваш-ip>:8000/api/v1` (галочку «Shared» не ставьте).
3. Выберите симулятор или устройство, запустите схему **Scentence** (`⌘R`).

## Структура проекта

```
Scentence/
├── App/                  # Точка входа, AuthState, AppState, корневая навигация
├── Core/
│   ├── Models/           # Codable-модели (Perfume, Auth, Search, User)
│   ├── Services/         # APIService, KeychainService, AppleIntelligenceService
│   └── Extensions/       # Цветовая тема, view-модификаторы
├── Features/
│   ├── Auth/             # Вход по email + OTP
│   ├── Search/           # Поиск и фильтры
│   ├── Results/          # Результаты подбора, шеринг
│   ├── PerfumeDetail/    # Детальная карточка аромата
│   ├── Favorites/        # Избранное
│   ├── History/          # История запросов
│   └── Profile/          # Профиль и настройки
└── UI/Components/        # Переиспользуемые компоненты

ScentenceTests/           # Unit-тесты моделей и ViewModel
```

## Архитектура

**MVVM**: `@MainActor ObservableObject` ViewModel с `@Published`-свойствами и async/await, SwiftUI-View через `@StateObject` / `@ObservedObject`, глобальное состояние через `@EnvironmentObject`.

`APIService` реализует `APIServiceProtocol` — интерфейс подменяется моками в тестах. Токены хранятся в Keychain с авто-рефрешем по 401.

## Тесты

```bash
xcodebuild test -project Scentence.xcodeproj -scheme Scentence \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```
