	# Variabelen invullen om gebruiker aan te kunnen maken
  
		$server = Read-host "Voer naam van remote server / computer"
		$Username = Read-host "Voer gebruikersnaam in om aan te maken"
		$Password = Read-host "Voer wachtwoord in (minimaal 3 karakters)"

	$userexist = Invoke-Command -ComputerName $server -ArgumentList $Username -ScriptBlock { param($Username) Get-LocalUser | Where-Object {$_.Name -eq $Username} } 
		if ($userexist){
			[System.Windows.Forms.MessageBox]::Show( "Gebruiker $Username bestaat al op $server" )
		} else {
				foreach ($computer in $server){

				Invoke-Command -ComputerName $computer -ScriptBlock { net accounts /minpwlen:3 }
				Invoke-Command -ComputerName $computer -ScriptBlock {
								secedit /export /cfg c:\secpol.cfg
								(gc C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg
								secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY
								rm -force c:\secpol.cfg -confirm:$false
							} 

					$group = "Users"
					$username = "$Username" # Gebruikersnaam
					$password = "$Password" # Wachtwoord
					$comp = [ADSI]"WinNT://$computer"
    
					$user = $comp.Create("User","$username")
					   $user.SetPassword("$password")
					   #$user.Put("Description","$description")
					   $user.Put("Fullname","$username")
					   $user.SetInfo()         
                             
					   #Set password to never expire
					   #And set user cannot change password
					   $ADS_UF_DONT_EXPIRE_PASSWD = 0x10000 
					   $ADS_UF_PASSWD_CANT_CHANGE = 0x40
					   $user.userflags = $ADS_UF_DONT_EXPIRE_PASSWD + $ADS_UF_PASSWD_CANT_CHANGE
					   $user.SetInfo()

					$group = [ADSI]"WinNT://$computer/$group,group"
					   $group.add("WinNT://$computer/$username")


				Invoke-Command -ComputerName $computer -ScriptBlock {
									secedit /export /cfg c:\secpol.cfg
									(gc C:\secpol.cfg).replace("PasswordComplexity = 0", "PasswordComplexity = 1") | Out-File C:\secpol.cfg
									secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY
									rm -force c:\secpol.cfg -confirm:$false
								}
				Invoke-Command -ComputerName $computer -ScriptBlock { net accounts /minpwlen:7 }

				$userexist = Invoke-Command -ComputerName $computer -ScriptBlock { Get-LocalUser | Where-Object {$_.Name -eq "$username"} } 
				if ($userexist){
					[System.Windows.Forms.MessageBox]::Show( "Gebruiker $Username is aangemaakt op $computer" )
				} else {
					[System.Windows.Forms.MessageBox]::Show( "Gebruiker $Username kon niet aangemaakt worden op $computer" )
				}
			} 
		}
