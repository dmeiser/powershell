# Sets group IDs for Users in Active Directory

Param(
	[Parameter(Position=0,mandatory=$true)]
	[string]$userName
)

Function checkAccount{
	Get-ADUser -Identity $userName
}

Function checkPrimaryGroupGid { 
	Get-ADUser $userName -Properties PrimaryGroup | select -ExpandProperty PrimaryGroup | 
		Get-ADGroup -Properties gidNumber | select -ExpandProperty gidNumber
}

Function nextUid {
	#gets the next avalible uidNumber to assign to the object
	$uidNum = Get-ADObject -filter { uidNumber -like "*" } -Properties uidNumber | 
		select -ExpandProperty uidNumber | sort uidNumber
	$next = $uidNum | Measure -Maximum | select -ExpandProperty maximum
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

Function checkUser {
	$uid = Get-ADUser -Identity $userName -Properties * | select -ExpandProperty uidNumber
	$primaryGid = checkPrimaryGroupGid
	if ( $uid -ne $null ){
		Write-Output "$userName already has UID #$uid"
	}
	elseif ( $primaryGid -eq $null ) {
		Write-Output "Primary group does not have GID, please check to ensure that GIDs are being set."
	}
	else {
		$uidNumber = nextUid

		Set-ADUser -Identity $userName -replace @{loginShell = "/bin/bash"}
		Set-ADUser -Identity $userName -replace @{homeDirectory = "/home/AMDX/$userName"}
		Set-ADUser -Identity $userName -replace @{gidNumber = "$primaryGid"}
		Set-ADUser -Identity $userName -replace @{uidNumber = "$uidNumber"}

		Write-Output "Unix attributes added to $userName. uidNumber is $uidNumber"
	}
}

$checkAccount = checkAccount

if ( $checkAccount -ne $null ) {
	checkUser
}
else {
	Write-Output "User not found in Active Directory"
}

