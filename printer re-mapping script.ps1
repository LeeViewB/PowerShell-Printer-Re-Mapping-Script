## Importing CSV files
$csv = Import-Csv "servers.csv"
$printerList = Import-Csv "PrinterName.csv"

Write-Host "Checking OS version. Running Get-Printer command based on W7 or W10 OS"
$osVersion = [System.Environment]::OSVersion.Version.Major

If($osVersion -eq 10){
    #################################
    ## Commands for Windows 10 OS
    #################################

    Write-Host "Windows 10 OS detected"
    $printers = @()
    $printers = Get-Printer | select *
    Foreach($printer in $printers){
                
        #######################################################################################
        ## Start IF#1. The script will continue only if the printer is a network printer.
        ## If it's a local printer, the script won't touch that.
        #######################################################################################
                                                
        If($printer.Type -eq "Connection"){
                        
            [string]$fullPrinterName = $printer.Name
            [string]$printerDeviceName = $printer.ShareName
            Write-Host "Found network printer mapped: $printerDeviceName. The full name of the printer is: $fullPrinterName" -Severity 2                    
            #Write-Host "The printer device name is $printerDeviceName"

            $myPrinter = $printerList | Where-Object {$_.PrinterName -eq "$printerDeviceName"}
            $myPrinterUpdatedVariable = $myPrinter.PrinterName
            #Write-Host $myPrinterUpdatedVariable

            ###########################################################################################################
            ## Start IF #2. It will get the printer name and check if it's one that needs to be migrated.
            ## If Yes, the script will move on to see if it's mapped from the old print server or not.
            ## If No, the script won't touch that printer.
            ## If it's mapped from the old server, it will remap it from the new corresponding server.
            ## IF it's mapped from the new server, it won't touch that printer.
            ###########################################################################################################

            If($printerDeviceName -eq $myPrinterUpdatedVariable){
                Write-Host "$printerDeviceName was found on the PrinterList with migrated printers. Checking it's server to see if it's mapped from the old one."
                [string]$currentPrintServer = $printer.ComputerName
                Write-Host "The Print Server name for this mapped printer is: $currentPrintServer" -Severity 2
        
                $myServ = $csv | Where-Object {$_.OldServer -eq "$currentPrintServer"}
                #Write-Host "MyServ is: $myServ"
        
                $oldServer = $myServ.oldServer

                Write-Host "Checking if $currentPrintServer is found in the `"OldServer`" column in the CSV file..."

                #################################################################################################################################################
                ## Start IF #3. It will Check agains the print server to see if it's mapped to the old one, and if yes, it will remap it to the new server.
                #################################################################################################################################################
                If($currentPrintServer -eq $oldServer){
                    $newServer = $myServ.NewServer
                    Write-Host "$currentPrintServer was found in the `"OldServer`" column in the CSV file! It's coresponding new value will be $newServer. Performing update..." -Severity 2
                    Write-Host "Deleting $printerDeviceName" -Severity 3
                    Get-WmiObject Win32_Printer | where{$_.ShareName -eq $printerDeviceName} | foreach{$_.delete()}
                            
                    ## 2 obsolete lines.
                    <#$printerToRemove = Get-Printer -Name $printerDeviceName
                    Remove-Printer -InputObject $printerToRemove#>

                    $newFullPrinterName = $printer.Name -replace($oldServer,$newServer)
                    $newPrinterServer = $printer.ComputerName -replace("$oldServer","$newServer")
                    Write-Host "The new full printer name is going to be: $newFullPrinterName"
                    Write-Host "The new print server for the printer is going to be: $newPrinterServer"
                    Write-Host "Remapping printer..."
                    ([wmiclass]"Win32_Printer").AddPrinterConnection($newFullPrinterName)
                }else{
                    Write-Host "$currentPrintServer was NOT found in the `"OldServer`" column in the CSV file! Nothing to do..."
                }
                #############################################
                ## ^ end IF#3 - print server name check
                #############################################
            }else{
                Write-Host "$printerDeviceName was not found in the PrinterList with the migrated printers. This printer won't be migrated. Nothing to do..."
            }
            ####################################
            ## ^ end IF#2 - printer name check
            ####################################

        }else{
            $localPrinter = $printer.Name
            Write-Host "$localPrinter is local. Not touching this printer"
        }
        ################################################################
        ## ^ end IF #1 - check to see if printer is local or network
        ################################################################
    }
    ##################
    ## ^ end FOREACH
    ##################
}else{
    ###############################
    ## Commands for Windows 7 OS
    ###############################
                
    Write-Host "Windows 7 OS detected"
    $printers = @()
    $printers = get-wmiobject win32_printer | select *

    Foreach($printer in $printers){
                
        #######################################################################################
        ## Start IF#1. The script will continue only if the printer is a network printer.
        ## If it's a local printer, the script won't touch that.
        #######################################################################################
        If($printer.Network -eq $true){
            [string]$fullPrinterName = $printer.Name
            [string]$printerDeviceName = $printer.ShareName
            Write-Host "Found network printer mapped: $printerDeviceName The full name of the printer is: $fullPrinterName" -Severity 2
                    
            $myPrinter = $printerList | Where-Object {$_.PrinterName -eq "$printerDeviceName"}
            $myPrinterUpdatedVariable = $myPrinter.PrinterName
            #Write-Host $myPrinterUpdatedVariable
                    
            ###########################################################################################################
            ## Start IF #2. It will get the printer name and check if it's one that needs to be migrated.
            ## If Yes, the script will move on to see if it's mapped from the old print server or not.
            ## If No, the script won't touch that printer.
            ## If it's mapped from the old server, it will remap it from the new corresponding server.
            ## IF it's mapped from the new server, it won't touch that printer.
            ###########################################################################################################    

            If($printerDeviceName -eq $myPrinterUpdatedVariable){
                                            
                Write-Host "$printerDeviceName was found on the PrinterList with migrated printers. Checking it's server to see if it's mapped from the old one."
                [string]$currentPrintServer = $printer.ServerName
                $currentPrintServer = $currentPrintServer.Replace("\\","")
                Write-Host "The Print Server name for this mapped printer is: $currentPrintServer" -Severity 2
        
                $myServ = $csv | Where-Object {$_.OldServer -eq "$currentPrintServer"}
                #Write-Host "MyServ is: $myServ"
        
                $oldServer = $myServ.oldServer

                Write-Host "Checking if $currentPrintServer is found in the `"OldServer`" column in the CSV file..."

                #################################################################################################################################################
                ## Start IF #3. It will Check agains the print server to see if it's mapped to the old one, and if yes, it will remap it to the new server.
                #################################################################################################################################################
                If($currentPrintServer -eq $oldServer){
                    $newServer = $myServ.NewServer
                    Write-Host "$currentPrintServer found in the `"OldServer`" column in the CSV file! It's coresponding new value will be $newServer. Performing update..." -Severity 2
                    Write-Host "Deleting $printerDeviceName" -Severity 3
                    Get-WmiObject Win32_Printer | where{$_.ShareName -eq $printerDeviceName} | foreach{$_.delete() }
            
                    $newFullPrinterName = $printer.Name -replace($oldServer,$newServer)
                    $newPrinterServer = $printer.ServerName -replace("$oldServer","$newServer")
                    Write-Host "The new printer name is going to be: $newFullPrinterName"
                    Write-Host "The new print server for the printer is going to be: $newPrinterServer"
                    Write-Host "Remapping printer..."
                    ([wmiclass]"Win32_Printer").AddPrinterConnection($newFullPrinterName)
                }else{
                    Write-Host "$currentPrintServer was NOT found in the `"OldServer`" column in the CSV file! Nothing to do..."
                }
                #############################################
                ## ^ end IF#3 - print server name check
                #############################################

            }else{
                Write-Host "$printerDeviceName was not found in the PrinterList with the migrated printers. This printer won't be migrated. Nothing to do..."
            }
            ####################################
            ## ^ end IF#2 - printer name check
            ####################################

        }else{
            Write-Host $printer.Name
            Write-Host "is local"
        }
        ################################################################
        ## ^ end IF #1 - check to see if printer is local or network
        ################################################################
    }
    ##################
    ## ^ end FOREACH
    ##################
}