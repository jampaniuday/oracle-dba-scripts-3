#!/bash/bin
source ~/.bash_profile
export db_list='test01'
export SYSPASS=''
fun() {
for i in $db_list; do
sqlplus -s $SYSPASS@$i as sysdba <<EOF
prompt HHHHHHHHHHHHHHHHh;
prompt say what ever you want to say but say it with a semicolon;
prompt $db_list
SET SERVEROUTPUT ON
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEXT GOES HERE ');
END;
/

SET LINESIZE 200
select name from v\$database;
show parameter CONTROL_MANAGEMENT_PACK_ACCESS
EOF
done
}
fun

exit 0
