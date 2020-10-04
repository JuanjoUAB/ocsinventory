<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class IpRange extends Model
{
    /**
     * Performs a search of a given ip address of a device and search the centre which belongs, using CIDR annotation sotred in database
     * @param string $ipAddr The local ip address of a computer or device
     * @return Illuminate\Database\Eloquen\Model|null Null when not found centre, the correct Model when found
     */
    public static function getCentreFromIp(string $ipAddr) {
        $ipAddresses = self::select('id', 'ip_range')->get();
        if($ipAddresses->isEmpty()) {
            return null;
        }
        $id = null;
        foreach($ipAddresses as $itemIpAddress) {
            //Gets the netmask ip from cidr annotation (158.109.0.0/16 -> 255.255.0.0)
            $ipMask = cidr2NetmaskAddr($itemIpAddress->ip_range);

            $ipAddrNum = ip2long($ipAddr);
            $netmaskNum = ip2long($ipMask);

            //Performs the correct and operation: 158.109.42.42 AND 255.255.252.0 = 158.109.40.0
            $resultAddrNum = $ipAddrNum & $netmaskNum;
//            echo "{$ipAddr} AND {$ipMask} = " . long2ip($resultAddrNum);

            $ipAddrMask = substr($itemIpAddress->ip_range, 0, strpos($itemIpAddress->ip_range, "/"));
            //echo "Ip address mask: {$ipAddrMask}";
            $ipAddMaskNum = ip2long($ipAddrMask);
            //Search which ip range is the same as resulting ip and address operation
            if($ipAddMaskNum == $resultAddrNum) {
                //echo "Found center at id {$itemIpAddress->id}";
                $id = $itemIpAddress->id;
                break;
            }
            //break;
        }

        return self::find($id);
    }
}
