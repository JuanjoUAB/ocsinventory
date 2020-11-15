# @link: https://planet.mysql.com/entry/?id=29283
DROP FUNCTION IF EXISTS cidr_to_mask;
CREATE FUNCTION cidr_to_mask (cidr INT(2)) RETURNS CHAR(15) DETERMINISTIC RETURN INET_NTOA(CONV(CONCAT(REPEAT(1,cidr),REPEAT(0,32-cidr)),2,10));
# @link: https://planet.mysql.com/entry/?id=29283
DROP FUNCTION IF EXISTS mask_to_cidr;
CREATE FUNCTION mask_to_cidr (mask CHAR(15)) RETURNS INT(2) DETERMINISTIC RETURN BIT_COUNT(INET_ATON(mask));


DROP FUNCTION IF EXISTS f_get_centre_from_ip;
DELIMITER $$
CREATE FUNCTION f_get_centre_from_ip (in_local_ip VARCHAR(15)) RETURNS BIGINT DETERMINISTIC
BEGIN
    DECLARE _ip_mask VARCHAR(15);
    DECLARE _centre VARCHAR(50);
    DECLARE _ip_centre VARCHAR(15);
    DECLARE _id_ip_range BIGINT;


    SELECT sql_calc_found_rows id, centre, SUBSTRING_INDEX(ip_range, '/', 1) as ip_centre, cidr_to_mask(CONVERT(SUBSTRING_INDEX(ip_range, '/', -1), INT)) AS ip_mask INTO _id_ip_range, _centre, _ip_centre, _ip_mask from ip_ranges
    HAVING INET_ATON(in_local_ip) & INET_ATON(ip_mask) = INET_ATON(ip_centre) LIMIT 1;
    IF FOUND_ROWS() = 0 THEN
        #SIGNAL SQLSTATE '45000'
        #    SET MESSAGE_TEXT = 'Not found rows';
        RETURN NULL;
    end if;
    RETURN _id_ip_range;
END$$

DELIMITER ;

DELIMITER $$
DROP PROCEDURE IF EXISTS p_update_ip_ranges $$
CREATE PROCEDURE p_update_ip_ranges()
BEGIN
    DECLARE _finished INTEGER DEFAULT 0;
    DECLARE _id INTEGER;
    DECLARE _output TEXT DEFAULT '';
    DECLARE _cursor_hardware_all CURSOR FOR SELECT id FROM hardware;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished=1;
    OPEN _cursor_hardware_all;
    getHardwareId: LOOP
        FETCH _cursor_hardware_all INTO _id;
        IF _finished = 1 THEN
            LEAVE getHardwareId;
        end if;
        UPDATE hardware SET ip_range_id=f_get_centre_from_ip(IPADDR) WHERE id=_id;
        IF ROW_COUNT() > 0 THEN
            SET _output = CONCAT(_output, 'Updated id ', _id);
        ELSE
            SET _output = CONCAT(_output, 'Error updating row ', _id);
        end if;
    end loop;
    CLOSE _cursor_hardware_all;
    SELECT _output;
END $$
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS t_ins_ip_range_id;
CREATE TRIGGER t_ins_ip_range_id
    AFTER INSERT
    ON hardware FOR EACH ROW
BEGIN

    IF NEW.ip_range_id IS NULL THEN
        CALL p_update_ip_ranges();
    end if;

end $$
DELIMITER ;
select ip_range, inet_ntoa(inet_aton(substring_index(ip_range, '/', 1)) & 0xffffffff ^ ((0x1 << (32 - SUBSTRING_INDEX(ip_range, '/', -1)) -1))) from ip_ranges;
select inet_ntoa(0xffffffff ^ ((0x1 << (32 - substring_index(ip_range, '/', -1)) -1))) from ip_ranges;
select '158.109.240.111' AS ip, centre, SUBSTRING_INDEX(ip_range, '/', 1) as ip_centre, cidr_to_mask(CONVERT(SUBSTRING_INDEX(ip_range, '/', -1), INT)) AS ip_mask from ip_ranges
HAVING INET_ATON(ip) & INET_ATON(ip_mask) = INET_ATON(ip_centre);
