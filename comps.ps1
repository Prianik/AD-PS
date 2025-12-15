#установить модули
#Install-WindowsFeature -Name RSAT-AD-PowerShell
#Import-Module ActiveDirectory
param(
    [Alias('d')]
    [int]$day,                 # необязательный, если не задан — без фильтра по дате

    [Alias('n')]
    [string]$name,             # необязательный, если не задан — без фильтра по имени (Name -like '*строка*')

    [Alias('e')]
    [ValidateSet('enable','disable')]
    [string]$enabled,          # enable / disable, если не задан — все

    [Alias('h')]
    [switch]$help,             # показать справку

    [string]$export,           # путь к CSV для экспорта

    [switch]$disable_yes,      # если указан — отключить отобранные компьютеры
    [switch]$delete_yes        # если указан — удалить отобранные компьютеры
)

if ($help) {
    Write-Host @"
Использование:
  .\comps.ps1 [-d <дней>] [-n <строка>] [-e <enable|disable>] [-export <путь_к_csv>] [-disable_yes] [-delete_yes] [-h]

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

  -delete_yes   Если указан, ВСЕ отобранные компьютеры будут УДАЛЕНЫ из AD (Remove-ADComputer -Confirm:`$false).
                Использовать максимально осторожно.

  -h            Показать эту справку.
"@
    return
}

if ($day) {
    $Date = (Get-Date).AddDays(-$day)
}

if ($name) {
    # подстрочный поиск, а не только префикс
    $filter = "Name -like '*$name*'"
} else {
    $filter = '*'
}

$computers = Get-ADComputer -Filter $filter -Properties LastLogonDate,Enabled |
    Where-Object {
        (-not $day     -or $_.LastLogonDate -lt $Date) -and
        (-not $enabled -or
            ($enabled -eq 'enable'  -and $_.Enabled -eq $true)  -or
            ($enabled -eq 'disable' -and $_.Enabled -eq $false)
        )
    } |
    Sort-Object Name

# Общий объект вывода
$out = $computers |
    Select-Object Name,LastLogonDate,Enabled,DistinguishedName

# Вывод на экран
$out | Format-Table -AutoSize

# Экспорт (если указан -export)
if ($export -and $out) {
    $out | Export-Csv -Path $export -NoTypeInformation -Encoding UTF8
}

# Отключение (если указан -disable_yes)
if ($disable_yes -and $computers) {
    Write-Host "`nОтключаю отобранные компьютеры..." -ForegroundColor Yellow
    $computers | Disable-ADAccount
    Write-Host "Готово (отключение)." -ForegroundColor Green
}

# Удаление (если указан -delete_yes)
if ($delete_yes -and $computers) {
    Write-Host "`nВНИМАНИЕ: будут УДАЛЕНЫ отобранные компьютеры из AD..." -ForegroundColor Red
    $computers | Remove-ADComputer -Confirm:$false
    Write-Host "Готово (удаление)." -ForegroundColor Green
}

