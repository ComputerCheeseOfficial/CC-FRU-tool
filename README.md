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
Chassis Part Number=
Chassis Serial Number=

[Board Info Area]
Mfg Date Time=
Board Manufacturer=
Board Product Name=
Board Serial Number=
Board Part Number=

[Product Info Area]
Manufacturer Name=
Product Name=
Product Part/Model Number=
Product Version=
Product Serial Number=
Asset Tag=
```
For example in fru_conf_example.conf file:
```
[Chassis Info Area]
Chassis Part Number=CC 0004
Chassis Serial Number=CC 0004

[Board Info Area]
Mfg Date Time=20230822 14:00:00
Board Manufacturer=Computer Cheese
Board Product Name=CC-FRU-tool
Board Serial Number=CC-FRU-tool V04
Board Part Number=CC 0004

[Product Info Area]
Manufacturer Name=Computer Cheese
Product Name=CC-FRU-tool V0.4
Product Part/Model Number=MODEL-2023
Product Version=0.4
Product Serial Number=CC20230822V04
Asset Tag=Computer Cheese 20230822
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

After writing the example configurations:
```
FRU Device Description : Builtin FRU Device (ID 0)
 Chassis Type          : Rack Mount Chassis
 Chassis Part Number   : CC 0004
 Chassis Serial        : CC 0004
 Board Mfg Date        : Tue Aug 22 20:10:00 2023
 Board Mfg             : Computer Cheese
 Board Product         : CC-FRU-tool
 Board Serial          : CC-FRU-tool V04
 Board Part Number     : CC 0004
 Product Manufacturer  : Computer Cheese
 Product Name          : CC-FRU-tool V0.4
 Product Part Number   : MODEL-2023
 Product Version       : 0.4
 Product Serial        : CC20230822V04
 Product Asset Tag     : Computer Cheese 20230822
```
## Doc Reference
[IPMI v2.0, rev. 1.1 markup for Errata 7, April 21, 2015](https://www.intel.com.tw/content/www/tw/zh/servers/ipmi/ipmi-intelligent-platform-mgt-interface-spec-2nd-gen-v2-0-spec-update.html)

[IPMI Platform Management FRU Information Storage Definition, v1.0, Document, Revision 1.3, March 24, 2015](https://www.intel.com.tw/content/www/tw/zh/servers/ipmi/ipmi-platform-mgt-fru-infostorage-def-v1-0-rev-1-3-spec-update.html)
