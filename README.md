# PowerShell-Printer-Re-Mapping-Script

If you are moving from some old print servers to some new ones and will migrate only some printers from the old print servers to the new one and would like to re-map only those printers which are mapped only to the "old print server" without touching all the other printers, this script will help you to achieve this.

You will need: 
1. A CSV file named "PrinterName.csv" --> put in here all the printers that need to be remapped.
2. A CSV file named "servers.csv" with 2 columns (oldServer, newServer) --> put in here the print server names (old, and it's coresponding new name). 
3. In the powershell script, add the path to your csv files (may be $PSScriptRoot, if they reside in the same folder as the script).
4. Deploy.

What the script will do:

1. Will get a list of all mapped printers from the computer.
2. It will check whether they are local or network printers or not. If they are local, the script won't touch them. If they are network printers...
3. The script will then get the name of the printer and check in the "PrinterName.csv" file to see if it finds it there. IF it won't find it, it will leave the printer alone. If it will find it....
4. The script will then look at the print server for that mapped printer and then look in the "servers.csv" file to see if it will find it there. If it won't find it in the "oldServer" column, the script will leave the printer alone.
If it will find the print server for that printer in the "oldServer" column, then it will delete that printer and re-map it from the coresponding "newServer" entry in the servers.csv file. 

IMPORTANT: It is mandatory for printer to exist on the new print server, otherwise the mapping of the printer from the new print server will fail, obviosly. 
