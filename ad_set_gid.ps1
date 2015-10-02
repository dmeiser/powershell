# Sets group IDs for Groups in Active Directory  See Comment to run as batch.

# Run as batch:  
# $groups = Get-ADGroup -Properties gidNumber -Filter * | Where { $_.gidNumber -eq $Null }
# foreach ( $group in $groups ) { .\ad_set_gid $group.SamAccountName }

Param(
	[Parameter(Position=0,mandatory=$true)]
	[string]$groupName
)

Function checkGroup {
	Get-ADGroup -Identity $groupName
}

Function nextGid {
	#gets the next avalible gidNumber to assign to the object
	$gidNum = Get-ADGroup -filter { gidNumber -like "*" } -Properties gidNumber | 
		select -ExpandProperty gidNumber | sort gidNumber
	$next = $gidNum | Measure -Maximum | select -ExpandProperty maximum
	#skips UID 110000
	if ( $next -eq 110000 -or $next -eq $null ) {
		$next = 110001
		$next
	}
	else {
		$next++
		$next 
	}
}

Function checkGroup {
	$gid = Get-ADGroup -Identity $groupName -Properties gidNumber | select -ExpandProperty gidNumber
	if ( $gid -ne $null ){
		Write-Output "$groupName already has GID $gid"
	}
	else {
		$gidNumber = nextGid

		Set-ADGroup -Identity $groupName -replace @{gidNumber = "$gidNumber"}

		Write-Output "gidNumber $gidNumber added to $groupName"
	}
}

$checkGroup = checkGroup

if ( $checkGroup -ne $null ) {
	checkGroup
}
else {
	Write-Output "Group not found in Active Directory"
}

