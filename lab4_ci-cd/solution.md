# Лабораторная работа №4. CI/CD

## Часть 1

Так как я работаю с `GitHub`, то буду рассматривать создаие `CI/CD-файла` для `GitHub Actions`. Будем считать, что данная папка `lab4_ci-cd` - это корень репозитория с нашим проектом, который мы хотим собирать, тестировать и деплоить.

### Плохой CI/CD-файл

```
vim .github/workflows/bad-practice.yml
name: CI/CD for DevOps Lab4

on:
  push:
    branches: [ main ] # 1. Хардкод имени ветки (тут неизбежен, к сожалению, как выяснилось) + 2. Не указано, что триггерится только при изменении недокументационных файлов в папке проекта
  pull_request:
    branches: [ main ]

jobs:
  lint:
    runs-on: ubuntu-latest # 3. Не указывать конкретную версию ОС, а использовать latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - name: Lint with flake8
        working-directory: lab4_ci-cd
        run: |
          pip install flake8 # 3. Не указывать конкретную версию библиотеки
          flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
    timeout-minutes: 10
          
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - name: Install Dependencies
        working-directory: lab4_ci-cd
        run: pip install -r requirements.txt
      - name: Run Tests
        working-directory: lab4_ci-cd
        run: python test.py
    timeout-minutes: 10
        
  build: # 4. Отсутствие явных dependencies между job-ами
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'
          cache: 'pip'
      - name: Build Artifact
        run: |
          mkdir built-app
          rsync -av --exclude='.git' lab4_ci-cd/ built-app/
      - name: Upload Build Artifact
        uses: actions/upload-artifact@v4
        with:
          name: python-app
          path: ./built-app
    timeout-minutes: 10

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: python-app
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12' # 5. Отсутствие кеширования
      - name: Security Scan (Bandit)
        run: |
          pip install bandit # 3. Не указывать конкретную версию библиотеки
          bandit -r built-app
    timeout-minutes: 10

  deploy:
    environment: production
    if: github.ref == 'refs/heads/main' # 1. Хардкод имени ветки
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: python-app
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: "top-Secret-token" # 6. Хардкод токенов в файлах
          publish_dir: ./built-app
    timeout-minutes: 10
```

Pipeline содержит ряд антипаттернов:
- использование хардкода значений (ветки и секретов): это снижает гибкость и безопасность, так как при изменении ветки или утечке токена придется менять код и может привести к проблемам с безопасностью;
- отсутствие фиксации версий зависимостей: это снижает воспроизводимость, так как при каждом запуске pipeline может использоваться разная версия библиотек, что может приводить к различиям в поведении и ошибкам;
- использование mutable окружений: использование `ubuntu-latest` может приводить к тому, что при каждом запуске pipeline будет использоваться разная версия ОС и предустановленных инструментов, что снижает воспроизводимость и может приводить к ошибкам;
- отсутствие структурированной зависимости между job-ами: это может приводить к тому, что этапы будут выполняться даже при провале предыдущих, что снижает эффективность и может приводить к ненужным затратам ресурсов;
- отсутствие кэширования зависимостей: это увеличивает время выполнения pipeline, так как при каждом запуске придется заново устанавливать все зависимости, что может быть особенно критично для больших проектов;
- отсутствие ограничения на триггеринг pipeline только при изменении файлов проекта, что может приводить к ненужным запускам при изменении документации или других несущественных файлов
- отсутствие dependency graph между job-ами, что может приводить к тому, что этапы будут выполняться даже при провале предыдущих

Это снижает воспроизводимость, безопасность и переносимость CI/CD процесса.

### Хороший CI/CD-файл

```
vim .github/workflows/ci-cd.yml
name: CI/CD for DevOps Lab4

on:
  push:
    branches: [ main ]
    paths: # 2. Ограничение на триггеринг только при изменении недокуменционных файлов в папке проекта
      - 'lab4_ci-cd/**'
    paths-ignore:
      - '**.md'
  pull_request:
    branches: [ main ]

jobs:
  lint:
    runs-on: ubuntu-22.04 # 3. Указание конкретной версии ОС для стабильности окружения
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'
          cache: 'pip' # 5. Включение кэширования для ускорения установки зависимостей
      - name: Lint with flake8
        working-directory: lab4_ci-cd
        run: |
          pip install flake8==7.0.0 # 3. Указание конкретной версии библиотеки для стабильности
          flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
    timeout-minutes: 10
          
  test:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'
          cache: 'pip'
      - name: Install Dependencies
        working-directory: lab4_ci-cd
        run: pip install -r requirements.txt
      - name: Run Tests
        working-directory: lab4_ci-cd
        run: python test.py
    timeout-minutes: 10
        
  build:
    needs: [lint, test] # 4. Явное указание зависимостей между job-ами для правильного порядка выполнения
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'
          cache: 'pip'
      - name: Build Artifact
        run: |
          mkdir built-app
          rsync -av --exclude='.git' lab4_ci-cd/ built-app/
      - name: Upload Build Artifact
        uses: actions/upload-artifact@v4
        with:
          name: python-app
          path: ./built-app
    timeout-minutes: 10

  security:
    needs: build
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: python-app
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'
          cache: 'pip'
      - name: Security Scan (Bandit)
        run: |
          pip install bandit==1.7.5
          bandit -r built-app
    timeout-minutes: 10

  deploy:
    environment: production
    needs: security
    if: github.ref == format('refs/heads/{0}', github.event.repository.default_branch) # 1. Использование переменной для определения ветки
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: python-app
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }} # 6. Использование встроенных секретов GitHub для безопасности
          publish_dir: ./built-app
    timeout-minutes: 10
```

В этом файле я исправила все перечисленные антипаттерны, что повысило стабильность, безопасность и эффективность CI/CD процесса. Теперь pipeline будет более предсказуемым, безопасным и оптимизированным для проекта.
Как исправления повлияли на процесс:
- использование переменных для определения ветки позволяет легко менять ветку по умолчанию без необходимости менять код, что повышает гибкость;
- ограничение на триггеринг pipeline только при изменении файлов проекта снижает количество ненужных запусков, что экономит ресурсы и время;
- указание конкретных версий ОС и библиотек обеспечивает стабильность окружения и воспроизводимость результатов, что снижает вероятность ошибок из-за изменений в зависимостях;
- явное указание зависимостей между job-ами гарантирует правильный порядок выполнения и предотвращает выполнение этапов при провале предыдущих, что повышает эффективность; соблюдение принципа `fail-fast` позволяет быстрее обнаруживать и исправлять ошибки, что экономит время и ресурсы;
- включение кэширования для зависимостей значительно ускоряет выполнение pipeline, особенно для больших проектов, что улучшает производительность;
- использование встроенных секретов `GitHub` для токенов повышает безопасность, так как исключает риск утечки токенов через код и позволяет управлять доступом к секретам через интерфейс `GitHub`.