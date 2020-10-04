<?php
/**
 * Converts a CIDR ip notation format (X.Y.Z.K/N) to the netmask id formatted (i.e. 255.255.242.0)
 *
 * @param string $cidr
 * @return string|null Null when invalid cidr format, string with the current resulting netmask
 */
function cidr2NetmaskAddr (string $cidr) {

    $ta = substr ($cidr, strpos ($cidr, '/') + 1) * 1;
    if($ta === false) {
        return null;
    }
    $netmask = str_split (str_pad (str_pad ('', $ta, '1'), 32, '0'), 8);

    foreach ($netmask as &$element)
        $element = bindec ($element);

    return join ('.', $netmask);

}

