# CC-FRU-tool
Command-line utility for generating IPMI FRU raw commands to write FRU data to BMC

## How to use

### 1) Download the source
```
git clone https://github.com/ComputerCheeseOfficial/CC-FRU-tool.git
cd CC-FRU-tool
chmod +x frutool.sh
```

### 2) Modify fru.conf
Add basic FRU infomation to fru.conf file
```
[Chassis Info Area]
ChassisPartNumber=
ChassisSerialNumber=

[Board Info Area]
MfgDateTime=20190927 00:00:00
BoardManufacturer=
BoardProductName=
BoardSerialNumber=
BoardPartNumber=

[Product Info Area]
ManufacturerName=
ProductName=
ProductPartModelNumber=
ProductVersion=
ProductSerialNumber=
AssetTag=
```
For example:
```
[Chassis Info Area]
ChassisPartNumber=CC-0001
ChassisSerialNumber=CC-0001

[Board Info Area]
MfgDateTime=20191001 00:00:00
BoardManufacturer=ComputerCheese
BoardProductName=FRU_Tool
BoardSerialNumber=CC_0001
BoardPartNumber=CC_0001

[Product Info Area]
ManufacturerName=ComputerCheese
ProductName=ComputerCheese
ProductPartModelNumber=MODEL-2019
ProductVersion=0.1
ProductSerialNumber=SERIL0001
AssetTag=ComputerCheese
```
### 3) Generage fru.sh with IPMI raw commands
```
./frutool.sh
```

## Write FRU data to BMC by fru.sh
```
sudo ./fru.sh
```
For example:

After writing the expample configurations:
```
FRU Device Description : Builtin FRU Device (ID 0)
 Chassis Type          : Rack Mount Chassis
 Chassis Part Number   : CC-0001
 Chassis Serial        : CC_0001
 Board Mfg Date        : Fri Sep 27 05:00:00 2019
 Board Mfg             : ComputerCheese
 Board Product         : FRU_Tool
 Board Serial          : CC_0001
 Board Part Number     : CC_0001
 Product Manufacturer  : ComputerCheese
 Product Name          : ComputerCheese
 Product Part Number   : MODEL-2019
 Product Version       : 0.1
 Product Serial        : SERIL0001
 Product Asset Tag     : ComputerCheese
```
## Doc Reference
[IPMI v2.0, rev. 1.1 markup for Errata 7, April 21, 2015](https://www.intel.com.tw/content/www/tw/zh/servers/ipmi/ipmi-intelligent-platform-mgt-interface-spec-2nd-gen-v2-0-spec-update.html)

[IPMI Platform Management FRU Information Storage Definition, v1.0, Document, Revision 1.3, March 24, 2015](https://www.intel.com.tw/content/www/tw/zh/servers/ipmi/ipmi-platform-mgt-fru-infostorage-def-v1-0-rev-1-3-spec-update.html)
