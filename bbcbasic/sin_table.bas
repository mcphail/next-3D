   10 REM Create a SIN table
   20 :
   30 FOR I=0 TO 127
   40   S = SIN(I/128*PI)
   50   S = INT(ABS(S)*255)
   60   H$=STR$~(S): IF LEN(H$)=1 THEN H$="0"+H$
   70   IF I MOD 8 = 0 THEN PRINT "DB ";
   80   PRINT "0x";H$;
   90   IF I MOD 8 < 7 THEN PRINT ", "; ELSE PRINT
  100 NEXT
  