#!/bin/bash
if [ -f "fru.sh" ]; then  
    rm fru.sh
fi 

filename='fru.conf'
#filename='fru_conf_example.conf'

COMM_HEAR_VALE=()
INTL_AREA_VALE=()
CHAS_FILD_NAME=(ChassisPartNumber ChassisSerialNumber)
CHAS_FILD_VALE=()
CHAS_AREA_VALE=()
BOAD_FILD_NAME=(MfgDateTime BoardManufacturer BoardProductName BoardSerialNumber BoardPartNumber)
BOAD_FILD_VALE=()
BOAD_AREA_VALE=()
PROT_FILD_NAME=(ManufacturerName ProductName ProductPartModelNumber ProductVersion ProductSerialNumber AssetTag)
PROT_FILD_VALE=()
PROT_AREA_VALE=()

IPMI_COMD="ipmitool -I open raw 0x0a 0x12 0x00"

# Parse Field value
function FIELD_INQUIRY() {
    _READ_LINE=$1
    local -n _FILD_NAME=$2
    local -n _FILD_VALE=$3

    str=$(echo $_READ_LINE | awk -F"=" '{ print $1 }')

    for ((i=0; i < ${#_FILD_NAME[@]}; i++))
    do
        if [ "$str" == ${_FILD_NAME[$i]} ]; then
            _READ_STRG=$(echo $_READ_LINE | awk -F'[=]' '$0=$2')
            strlen=$(echo $_READ_STRG | awk '{print length}')

            if [ $strlen -ge 1 ] ; then
                _FILD_VALE[i]=${_READ_STRG}
            fi
        fi
    done
}

# Execute IPMI Command with the same argument and data argument
function AREA_INQUIRY() {
    _ARRY_START=$1
    arg2=$2
    local -n _ARRY_SAVE=$3
    var=""
    sp=" "
    sum=0
    TmpStr=""

    strlen=$((${#arg2}))

    if [ $strlen -eq 0 ] ; then
        TmpStr=C0
        return 0
    fi

    for ((x = 0; x < $strlen ; x++))
    do
        substr=${arg2:$x:1}
        var=$(printf %d\\n "'$substr")
        #ASCII Letter Case Changed ex: a changes to A
        #if [ "$var" -ge 97 ] && [ "$var" -le 122 ] ; then
        #  var=$(($var - 32))
        #fi

        #Sum all values in Dec
        sum=$(($sum+$var))
        #Change to Hex base
        var=`echo "obase=16; ${var}" | bc`
        i=$(( $x + $_ARRY_START ))
        _ARRY_SAVE[i]=$var
        TmpStr=$TmpStr$sp$var
    done
}

# Fetch Field data
function FETCH_FIELD_DATA()
{
    _ARRY_START=$1
    local -n _FILD_NAME_ARRY=$2
    local -n _FILD_VALE_ARRY=$3
    local -n _AREA_VALE_ARRY=$4
    
    for (( j=$_ARRY_START ; j < ${#_FILD_NAME_ARRY[@]} ; j++))
    do
        strlen=0
        strs="${_FILD_VALE_ARRY[j]}"
        strlen=$((${#strs}))
        #2022-04-08 Fixed issue about cannot over 15 characters
        strlen=$(($strlen + 192))
        x=${#_AREA_VALE_ARRY[@]}
        ## code bits 7:6=11b the serial number will always be
        ## interpreted as 8-bit ASCII+Latin 1, not 16-bit UNICODE.
        strlenHEX=`echo "obase=16; ${strlen}" | bc`
        #2022-04-08 Fixed issue about cannot over 15 characters
        _AREA_VALE_ARRY[x]=$strlenHEX

        x=${#_AREA_VALE_ARRY[@]}
        AREA_INQUIRY $x "${_FILD_VALE_ARRY[j]}" _AREA_VALE_ARRY
    done
}

function ADD_ZERO_BYTE()
{
    local -n _ARRY=$1

    #Write field length to area bype[1]
    x=${#_ARRY[@]}
    area_len=$(($x / 8 + 1))
    #Add leading 0
    area_lenHEX=$(printf "%02X" $area_len)
    #Area Length (in multiples of 8 bytes)
    _ARRY[1]=$area_lenHEX

    #Write 00 to reset bytes
    num_add_zero=$(($area_len * 8 - $x - 1))
    for ((i=0; i<$num_add_zero; i++))
    do
        p=$(($x + $i))
        _ARRY[p]=00
    done
}

function WRITE_CHECKSUM()
{
    local -n _ARRY=$1
    x=${#_ARRY[@]}
    sum=0
    sumDEC=0

    for ((i=0; i < x; i++))
    do
        subHEX=${_ARRY[i]}
        sumDEC=$(($sumDEC+$((16#$subHEX))))
    done

    CheckSumDEC=$((256-($sumDEC % 256)))
    CheckSumHEX=$(printf "%02X" ${CheckSumDEC})
    _ARRY[x]=$CheckSumHEX
}

#===============================================================================
#Read per line from file
exec < $filename
while read line
do
    FIELD_INQUIRY "$line" CHAS_FILD_NAME CHAS_FILD_VALE
    FIELD_INQUIRY "$line" BOAD_FILD_NAME BOAD_FILD_VALE
    FIELD_INQUIRY "$line" PROT_FILD_NAME PROT_FILD_VALE
done
#===============================================================================
##Internal Use Area
INTL_AREA_VALE[0]=01
INTL_AREA_VALE[1]=00
INTL_AREA_VALE[2]=01
INTL_AREA_VALE[3]=04
INTL_AREA_VALE[4]=00
INTL_AREA_VALE[5]=00
INTL_AREA_VALE[6]=03
INTL_AREA_VALE[7]=F7
#===============================================================================
##Chassis Info Area
#Chassis Info Area Format Version
CHAS_AREA_VALE[0]=01
#Chassis Info Area Length (in multiples of 8 bytes)
CHAS_AREA_VALE[1]=01
#Chassis Type
CHAS_AREA_VALE[2]=17

#Fetch Chassis fild data
FETCH_FIELD_DATA 0 CHAS_FILD_NAME CHAS_FILD_VALE CHAS_AREA_VALE

#Custom Chassis Info fields
x=${#CHAS_AREA_VALE[@]}
CHAS_AREA_VALE[x]=C0
#C1h (type/length byte encoded to indicate no more info fields)
x=${#CHAS_AREA_VALE[@]}
CHAS_AREA_VALE[x]=C1

#00h - any remaining unused space
#Add zero to empty bytes
ADD_ZERO_BYTE CHAS_AREA_VALE

#Chassis Info Checksum (zero checksum)
#Calculate Checksum
WRITE_CHECKSUM CHAS_AREA_VALE
#===============================================================================
##Board Info Area
#Board Area Format Version
BOAD_AREA_VALE[0]=01
#Board Area Length (in multiples of 8 bytes)
BOAD_AREA_VALE[1]=01
#Language Code
#0. en English*
BOAD_AREA_VALE[2]=00

#Such as change "20160101 00:00:00" to 0xA0822A
mfgdtstr="${BOAD_FILD_VALE[0]}"
#Date & Time in minutes from 1996
st_now=$(date +%s -d '1996-01-01 00:00:00')
dt=$(date +%s -d "$mfgdtstr")
dtnow=$((($dt-$st_now)/60))
datedfHEX=$(printf "%06X" ${dtnow})
H_CK=${datedfHEX:0:2}
M_CK=${datedfHEX:2:2}
L_CK=${datedfHEX:3:2}
#Mfg. Date / Time
BOAD_AREA_VALE[3]=$L_CK
BOAD_AREA_VALE[4]=$M_CK
BOAD_AREA_VALE[5]=$H_CK

#Fetch Board fild data
FETCH_FIELD_DATA 1 BOAD_FILD_NAME BOAD_FILD_VALE BOAD_AREA_VALE

#FRU File ID type/length byte
x=${#BOAD_AREA_VALE[@]}
BOAD_AREA_VALE[x]=C0
#Additional custom Mfg. Info fields
x=${#BOAD_AREA_VALE[@]}
BOAD_AREA_VALE[x]=C0

#C1h (type/length byte encoded to indicate no more info fields)
x=${#BOAD_AREA_VALE[@]}
BOAD_AREA_VALE[x]=C1

#00h - any remaining unused space
#Add zero to empty bytes
ADD_ZERO_BYTE BOAD_AREA_VALE

#Board Info Checksum (zero checksum)
#Calculate Checksum
WRITE_CHECKSUM BOAD_AREA_VALE
#===============================================================================
##Product Info Area
#Product Area Format Version
PROT_AREA_VALE[0]="01"
#Product Area Length (in multiples of 8 bytes)
PROT_AREA_VALE[1]="01"
#Language Code
#0. en English*
PROT_AREA_VALE[2]="00"

#Fetch Product fild data
FETCH_FIELD_DATA 0 PROT_FILD_NAME PROT_FILD_VALE PROT_AREA_VALE

#FRU File ID type/length byte
x=${#PROT_AREA_VALE[@]}
PROT_AREA_VALE[x]=C0
#Additional custom Mfg. Info fields
x=${#PROT_AREA_VALE[@]}
PROT_AREA_VALE[x]=C0

#C1h (type/length byte encoded to indicate no more info fields)
x=${#PROT_AREA_VALE[@]}
PROT_AREA_VALE[x]=C1
#00h - any remaining unused space
#Add zero to empty bytes
ADD_ZERO_BYTE PROT_AREA_VALE

#Board Info Checksum (zero checksum)
#Calculate Checksum
WRITE_CHECKSUM PROT_AREA_VALE
#===============================================================================
##Common Header
#Common Header Format Version
COMM_HEAR_VALE[0]=01
#Internal Use Area Starting Offset (in multiples of 8 bytes)
COMM_HEAR_VALE[1]=01
#Chassis Info Area Starting Offset (in multiples of 8 bytes)
COMM_HEAR_VALE[2]=02

#Board Area Starting Offset (in multiples of 8 bytes)
x=$((${#INTL_AREA_VALE[@]} + ${#CHAS_AREA_VALE[@]}))
offset=$(($x / 8 + 1))
offHEX=$(printf "%02X" ${offset})
COMM_HEAR_VALE[3]=$offHEX

#Product Info Area Starting Offset (in multiples of 8 bytes)
x=$((${#INTL_AREA_VALE[@]} + ${#CHAS_AREA_VALE[@]} + ${#BOAD_AREA_VALE[@]}))
offset=$(($x / 8 + 1))
offHEX=$(printf "%02X" ${offset})
COMM_HEAR_VALE[4]=$offHEX

#MultiRecord Area Starting Offset (in multiples of 8 bytes)
COMM_HEAR_VALE[5]=00
#PAD, write as 00h
COMM_HEAR_VALE[6]=00

#Common Header Checksum (zero checksum)
#Calculate Checksum
WRITE_CHECKSUM COMM_HEAR_VALE
#===============================================================================
##Print IPMI commands to file
bytestring=""
bytecount=1

function GET_OFFSET()
{
    offsetadd=0

    k=$(($bytecount - 8))
    offsetadd=$(printf "%02X" ${k})
    tmpoffsetstr="0x"$offsetadd" 0x00"

    export OFFSET_STRG="$tmpoffsetstr"
}

function PRINT_IPMI()
{
    local -n _ARRY=$1

    for ((i=0; i < ${#_ARRY[@]}; i++))
    do
        y=${_ARRY[i]}
        k=$(($bytecount % 8))
        bytestring=$bytestring" ""0x"$y

        if [ $k -eq 0 ] ; then
            GET_OFFSET
            echo $IPMI_COMD $OFFSET_STRG $bytestring >> fru.sh
            bytestring=""
        fi
        bytecount=$(($bytecount + 1))
    done

}
PRINT_IPMI COMM_HEAR_VALE
PRINT_IPMI INTL_AREA_VALE
PRINT_IPMI CHAS_AREA_VALE
PRINT_IPMI BOAD_AREA_VALE
PRINT_IPMI PROT_AREA_VALE
#===============================================================================
chmod +x fru.sh
cat fru.sh
echo Done

exit 0
