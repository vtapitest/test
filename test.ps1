# PowerShell script to count Active Directory group members by month
# Replace "YourGroupName" with the actual AD group name

# Import the Active Directory module
Import-Module ActiveDirectory

# Define the group name
$groupName = "YourGroupName"

# Get the current date and set it to April for this example
$currentDate = Get-Date -Month 4 -Day 30 -Year 2024

# Get all members of the specified group
$allMembers = Get-ADGroupMember -Identity $groupName | 
              Where-Object {$_.objectClass -eq "user"} | 
              ForEach-Object {Get-ADUser $_ -Properties whenCreated}

# Count total members
$totalMembers = $allMembers.Count

# Filter members by creation date
$aprilMembers = $allMembers | Where-Object {$_.whenCreated -ge (Get-Date -Month 4 -Day 1 -Year 2024) -and $_.whenCreated -le $currentDate}
$marchMembers = $allMembers | Where-Object {$_.whenCreated -ge (Get-Date -Month 3 -Day 1 -Year 2024) -and $_.whenCreated -lt (Get-Date -Month 4 -Day 1 -Year 2024)}
$februaryMembers = $allMembers | Where-Object {$_.whenCreated -ge (Get-Date -Month 2 -Day 1 -Year 2024) -and $_.whenCreated -lt (Get-Date -Month 3 -Day 1 -Year 2024)}
$januaryMembers = $allMembers | Where-Object {$_.whenCreated -ge (Get-Date -Month 1 -Day 1 -Year 2024) -and $_.whenCreated -lt (Get-Date -Month 2 -Day 1 -Year 2024)}

# Count members created in each month
$aprilCreated = $aprilMembers.Count
$marchCreated = $marchMembers.Count
$februaryCreated = $februaryMembers.Count
$januaryCreated = $januaryMembers.Count

# Calculate members present in each month (cumulative)
$aprilCount = $totalMembers
$marchCount = $totalMembers - $aprilCreated
$februaryCount = $marchCount - $marchCreated
$januaryCount = $februaryCount - $februaryCreated

# Create a results array for CSV export
$results = @()
foreach ($member in $allMembers) {
    $creationMonth = $member.whenCreated.Month
    $creationYear = $member.whenCreated.Year
    
    $monthName = switch ($creationMonth) {
        1 {"January"}
        2 {"February"}
        3 {"March"}
        4 {"April"}
        default {"Other"}
    }
    
    if ($creationYear -eq 2024 -and $creationMonth -le 4) {
        $results += [PSCustomObject]@{
            UserName = $member.SamAccountName
            DisplayName = $member.Name
            CreatedOn = $member.whenCreated
            CreationMonth = $monthName
        }
    }
}

# Export to CSV
$results | Export-Csv -Path "ADGroupMembersByMonth.csv" -NoTypeInformation

# Now display all results at the end
Clear-Host
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "   ACTIVE DIRECTORY GROUP MEMBERS BY MONTH    " -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "Group Name: $groupName" -ForegroundColor Green
Write-Host "Total members: $totalMembers" -ForegroundColor Green
Write-Host "Report Date: $(Get-Date)" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Cyan

Write-Host "`nMONTHLY MEMBER COUNTS (2024):" -ForegroundColor Yellow
Write-Host "-----------------------------------------------" -ForegroundColor Yellow
Write-Host "Month      | Created | Total Present" -ForegroundColor Yellow
Write-Host "-----------------------------------------------" -ForegroundColor Yellow
Write-Host "January    | $januaryCreated".PadRight(12) -NoNewline
Write-Host " | $januaryCount" -ForegroundColor White
Write-Host "February   | $februaryCreated".PadRight(12) -NoNewline
Write-Host " | $februaryCount" -ForegroundColor White
Write-Host "March      | $marchCreated".PadRight(12) -NoNewline
Write-Host " | $marchCount" -ForegroundColor White
Write-Host "April      | $aprilCreated".PadRight(12) -NoNewline
Write-Host " | $aprilCount" -ForegroundColor White
Write-Host "-----------------------------------------------" -ForegroundColor Yellow

Write-Host "`nDETAILED RESULTS:" -ForegroundColor Magenta
Write-Host "-----------------------------------------------" -ForegroundColor Magenta

# Function to format the month's data
function Format-MonthData {
    param (
        [string]$Month,
        [array]$CreatedUsers,
        [int]$TotalUsers
    )
    
    Write-Host "`n$Month 2024:" -ForegroundColor Cyan
    Write-Host "- Users created in $Month: $($CreatedUsers.Count)" -ForegroundColor White
    Write-Host "- Total users present in $Month: $TotalUsers" -ForegroundColor White
    
    if ($CreatedUsers.Count -gt 0) {
        Write-Host "`nUsers created in $Month:" -ForegroundColor Gray
        $CreatedUsers | ForEach-Object {
            Write-Host "  - $($_.SamAccountName) ($($_.Name)) - Created: $($_.whenCreated.ToString('yyyy-MM-dd'))" -ForegroundColor White
        }
    } else {
        Write-Host "  No users were created in $Month." -ForegroundColor Gray
    }
}

# Display detailed information for each month
Format-MonthData -Month "January" -CreatedUsers $januaryMembers -TotalUsers $januaryCount
Format-MonthData -Month "February" -CreatedUsers $februaryMembers -TotalUsers $februaryCount
Format-MonthData -Month "March" -CreatedUsers $marchMembers -TotalUsers $marchCount
Format-MonthData -Month "April" -CreatedUsers $aprilMembers -TotalUsers $aprilCount

Write-Host "`n===============================================" -ForegroundColor Cyan
Write-Host "Detailed information exported to: ADGroupMembersByMonth.csv" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Cyan
