# Управление пользователями и компьютерами в AD


**comps.ps1**
```
Параметры:
  -d            Количество дней без регистрации компьютера в домене (LastLogonDate старше).
                Если не задан, фильтра по дате нет.

  -n            Строка для поиска в Name (Name -like '*строка*').
                Если не задан, выбираются все имена.

  -e            Статус учетной записи компьютера:
                  enable  — только включенные (Enabled = True)
                  disable — только отключенные (Enabled = False)
                Если не задан, выводятся и включенные, и отключенные.

  -export       Путь к CSV-файлу для экспорта результата выборки.
                Если не задан, экспорт не выполняется.

  -disable_yes  Если указан, ВСЕ отобранные компьютеры будут отключены (Disable-ADAccount).

  -delete_yes   Если указан, ВСЕ отобранные компьютеры будут УДАЛЕНЫ из AD (Remove-ADComputer -Confirm:$false).
                Использовать максимально осторожно.

  -h            Показать эту справку.
```

**users.ps1**
```
Параметры:
  -d            Количество дней без входа (LastLogonDate старше).
                Если не задан, фильтра по дате нет.

  -n            Строка для поиска в Name (Name -like '*строка*').
                Если не задан, выбираются все имена.

  -e            Статус учетной записи:
                  enable  — только включенные (Enabled = True)
                  disable — только отключенные (Enabled = False)
                Если не задан, выводятся и включенные, и отключенные.

  -export       Путь к CSV-файлу для экспорта результата выборки.
                Если не задан, экспорт не выполняется.

  -disable_yes  Если указан, ВСЕ отобранные учетные записи пользователей будут отключены (Disable-ADAccount).

  -delete_yes   Если указан, ВСЕ отобранные учетные записи пользователей будут УДАЛЕНЫ из AD (Remove-ADUser -Confirm:$false).
                Использовать максимально осторожно.

  -h            Показать эту справку.
```


При необходимости установить модули для работы с powershell
## Windows 10 / 11 (рабочие станции)

Открой PowerShell **от имени администратора** и выполни:

```powershell
Get-WindowsCapability -Name RSAT.ActiveDirectory* -Online |
    Add-WindowsCapability -Online
```

После окончания установки перезапусти PowerShell и проверь:

```powershell
Import-Module ActiveDirectory
Get-ADComputer -Filter * -ResultSetSize 1
```

Если команда отрабатывает без ошибок, можно запускать `comps.ps1` и `users.ps1`.[^1][^2]

Альтернатива поставить все RSAT:

```powershell
Get-WindowsCapability -Name RSAT* -Online | Add-WindowsCapability -Online
```


## Windows Server (если запускаешь на сервере)

В PowerShell (админ):

```powershell
Install-WindowsFeature -Name RSAT-AD-PowerShell
```

затем:

```powershell
Import-Module ActiveDirectory
```

После этого `Get-ADUser`/`Get-ADComputer` появятся.[^3][^4]

## Проверка путей модулей (на всякий случай)

Можно посмотреть, куда PowerShell ищет модули:

```powershell
$env:PSModulePath -split ';'
```

Когда RSAT/роль установлена, в одном из этих путей должен появиться каталог `ActiveDirectory` с модулем.
