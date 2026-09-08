# ROS2 CUDA Cross-Platform Docker Build System

Система автоматической кросс-платформенной сборки Docker-образов для ROS2-пакетов с поддержкой CUDA.

## Требования

- Docker 20.10+
- Docker Buildx
- GitHub Actions (или GitLab CI)
- Для нативной сборки: NVIDIA Jetson AGX Orin / Orin Nano с JetPack 6.2.2

## Архитектура сборки

Сборка каждого образа состоит из двух стадий:

1. **Base-образ** (`docker/base/Dockerfile`) — сырой образ NVIDIA (CUDA
   devel для x86_64, или L4T JetPack для Jetson) плюс поверх него ROS2
   Humble, colcon, rosdep и типовые библиотеки (Eigen, OpenCV, PCL,
   Boost).
2. **Пакетный образ** (`docker/templates/Dockerfile.package`) —
   собирается **поверх** base-образа из шага 1, клонирует и собирает
   конкретный ROS2-пакет (по умолчанию — [FAST-LIO2](https://github.com/hku-mars/FAST_LIO)).

Оба скрипта (`build.sh`) и CI (`build.yml`) сначала собирают base-образ,
затем передают его как `BASE_IMAGE` для сборки пакета — это важно, если
будете модифицировать пайплайн: пропуск первого шага означает, что
`source /opt/ros/humble/setup.bash` во втором шаге просто не найдёт файл.

## Быстрый старт

1. Клонирование репозитория:
   ```bash
   git clone https://github.com/your-username/ros2-cuda-ci.git
   cd ros2-cuda-ci
   ```

2. Локальная сборка:
   ```bash
   # Сборка для x86_64
   ./scripts/build.sh x86_64

   # Сборка для Jetson (кросс-сборка через QEMU)
   ./scripts/build.sh orin-agx
   ./scripts/build.sh orin-nano
   ```

3. Тестирование собранного образа:
   ```bash
   ./scripts/test_cuda.sh ghcr.io/your-username/ros2-cuda-package:orin-agx-latest linux/arm64
   ```

4. Публикация:
   ```bash
   export GITHUB_TOKEN=ghp_xxxxx
   ./scripts/publish.sh latest
   ```

Все три скрипта читают `REGISTRY`/`OWNER` (и другие настройки) из файла
`.env` в корне репозитория, если он есть — скопируйте `.env.example` в
`.env` и подставьте свои значения перед первым запуском:

```bash
cp .env.example .env
# отредактируйте .env — минимум OWNER
```

## Добавление нового пакета

Проще всего — добавить новую запись в матрицу `.github/workflows/build.yml`,
указав нужный `target`/`base_image`/`cuda_arch`; шаблон
`docker/templates/Dockerfile.package` уже параметризован через
`REPO_URL`/`BRANCH`/`PACKAGE_NAME` и подойдёт для большинства пакетов
без изменений.

Если пакету нужна нестандартная логика сборки (дополнительные шаги,
патчи, отличная от `colcon build` команда) — создайте свой Dockerfile по
образцу `docker/templates/Dockerfile.package`, обязательно принимающий
`BASE_IMAGE` как `ARG` и собирающийся `FROM ${BASE_IMAGE}` (то есть
поверх уже готового base-образа с ROS2, а не поверх сырого образа
NVIDIA — см. «Архитектура сборки» выше).

## Мониторинг и метрики

| Метрика | Источник | Описание |
|---|---|---|
| Время сборки | GitHub Actions | Длительность каждого шага |
| Размер образа | GitHub Packages | Размер в реестре |
| Успешность тестов | GitHub Actions | Статус пайплайна |
| Кол-во загрузок | GitHub Packages | Статистика использования |

## Устранение проблем

**Проблема: QEMU не эмулирует ARM64.**
```bash
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

**Проблема: CUDA не доступна в контейнере.**

Для x86:
```bash
docker run --rm --gpus all your-image nvidia-smi
```

Для Jetson:
```bash
docker run --rm --runtime nvidia your-image nvidia-smi
```

**Проблема: недостаточно памяти при кросс-сборке.**

Добавьте флаги в Docker Buildx:
```bash
docker buildx build --memory=8g --swap=8g ...
```

## Лицензия

MIT License

## Автор

Сергеев Антон Валентинович
kavery@mail.ru
