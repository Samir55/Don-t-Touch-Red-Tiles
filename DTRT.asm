;Author: Ahmed Samir Hamed
;26-1-2017
;---------------------------
.MODEL large
.STACK 64
.DATA
SCREENCELLSCOUNT equ 2080; عدد الخلايا لللعبة
backgroundColor equ 07h;لون الخلفية رمادي علي اسود
PlayerColor equ 1; لون اللاعب ازرق
playerPos dw  3920; كان اللاعب الابتدائي
redTilessPos dw  390, 780, 1010, 1240, 1310, 1700, 1930, 2160, 2390, 2620, 2850, 3080, 3310, 3540, 3770
;اماكن المستطيلات الحمراء تم حسابها قبل برمجة اللعبة
initialTilesPos dw 390, 780, 1010, 1240, 1310, 1700, 1930, 2160, 2390, 2620, 2850, 3080, 3310, 3540, 3770
;الاماكن الابتدائية للمستطيلات تستخدم عند اعادة بدء اللعبة
redTilesMovement dw -8, 6, 8, -4, 4, 4, -4, -4, 2, 6, -4, -4, 8, 2, 2; سرعة المستطيلات الابتدائية
redTilesLowLimits dw  320, 640, 960, 1120, 1280, 1600, 1920, 2080, 2240, 2560, 2720, 3040, 3200, 3520, 3680
; الحدود الدنيا للمستطيلات في صفها
redTilesHighLimits dw  476, 796, 1116, 1276, 1436, 1756, 2076, 2236, 2396, 2716, 2876, 3196, 3356, 3676, 3836
; الحدود العليا للمستطيلات في صفها
currentDeciSec db ? ;الجزي من المائة من الثانيه الحاليه نحتاجه في حسابات تحريك المستطيلات
currentSec db ? ;الثانية الحالية
gameScore db 0 ;مجموع اللاعب
playerWasOnWhiteTile db 0;اذا كان لاعب قد وقف علي خلية لونها ابيض
PlayerPress db ? ;الزر الذس ضغطه اللاعب scancode
yellowLinePos db 0;مكان الصف الاصفر (الهدف) اذا كان صفر معناه انه فوق و 1 تعني انه اسفل
MilliSecSpeed db 6 ;القيمة البتدائية المسئولة عن سرعة المستطيلات
lastFourMultipleSCore db 0 ;تستخدم في حسابات زيادة سرعة المستطيلات حيث انها تسجل آخر مجموع من مضاعفات الاربعة
collisionDetected db 0;تستخدم لمعرفة التصادم عند تحرك اللاعب
.code
MAIN    PROC FAR
MOV AX,@DATA
MOV DS,AX

;تخزين عنوان الفيديو ميموري فال extra segment
mov ax, 0b800h
mov es, ax

jmp InitializeGame

RetryGameSelected:;تنفذ في حالة اختيار اعادة اللعبة من الاول
call far ptr RetryGameInitializations

InitializeGame:
call far ptr initScene ;بترسم الشكل الاولي لللعبة

;اللوب الرئيسية لللعبة
GameLoop:
;نحن هنا نحسب التغير في الوقت لكي نحرك المستطيلات الحمراء علي النحو الآتي
;اذا كانت الثواني مختلفة (الثانية الحالية و الثانية المسجلة) نحرك المسطيلات
;اذا كانت الثواني متساوية نقارن الجزء من المائة
;من الثانية , اذا كان الفارق اكبر من 600 ميللي ثانية نحرك المستطيلات
;الجزء من المائة من الثانية MilliSecSpeed
;هو المتحكم  فالسرعة
CheckTileMovement:
mov ah,2Ch;ناتي بالوقت الحالي
int 21h
cmp dh, currentSec;نقارن ي=بالثانية المسجلة
jne MoveTheTiles ;اذا كانت مخلفة نحرك
mov cl, currentDeciSec;هنا ناتي اذا كانت الثواني متساوية
add cl,MilliSecSpeed
cmp dl, cl
ja MoveTheTiles
jmp CheckForUserInput
MoveTheTiles:
mov currentDeciSec, dl;نحفظ في كل الحالات الوقت الجديد
mov currentSec, dh
call far ptr MoveAllTiles

;هنا نحن نري اذا كان قدس حدث اصطدام الاعب مع تحرك المستطيلات المميتة عن طريق الاتي
;اذا كان اللون في خلية ( مركز) اللاعب احمر
checkingCollision:
mov si, playerPos
mov al, es:[si+1]
cmp al, BYTE PTR 0Ch
jne CheckForUserInput
call far ptr DrawPlayer
jmp gameOver

CheckForUserInput: ;اذا جاء هنا معناه انه لم يحدث تصادم
mov ax, 0
mov ah, 1; ناخذ ضغطة الزر ان وجدت
int 16h
mov PlayerPress, ah
jnz GetUserInput;نري اذا الاعب ضغط زر ام لا
jmp CHECKYELLOW

GetUserInput:

;نتاكد من عدم ضغط زر الخروج
cmp playerPress,10h
jne checkRetryPressed
consumeletterBeforeQuit:
mov ah,0
int 16h
jmp exit

;نتاكد من عدم ضغط زر اعادة اللعبة من الاول
checkRetryPressed:
cmp playerPress, 13h
jne CheckArrowUP
consumeletterBeforeRetry:
mov ah,0
int 16h
jmp RetryGameSelected

;نري اذا ضغط زر اعلي ام لا
;اذا ضغط يجب ان نتاكد اذا كانت الحركة ممكنة(اي لا تجعل الاعب يخرج من حدود الشاشة)
; اذا كان مركز الاعب بعد اول صفين من الشاشة يمكنه التحرك لأعلي
CheckArrowUP:
cmp PlayerPress, 48h
jne CheckArrowDown
CheckUpValidMove:
mov ax, playerPos
cmp ax, BYTE PTR 320
jb DisaproveUpMove
mov di, playerPos
sub di,  160
call far ptr MovePlayer
DisaproveUpMove:
jmp consumeTheLetter;نحذف الزر من ال ;keyboard queue

;اذا ضغط اسفل
;اذا كان اللاعب مركزه قبل اخر صف يمكنه التحرك لاسفل
CheckArrowDown:
cmp PlayerPress, 50h
jne CheckArrowLeft
CheckDownValidMove:
mov ax, playerPos
cmp ax, WORD PTR 3840;
jae DisaproveDownMove
mov di, playerPos
add di,  160
call far ptr MovePlayer
DisaproveDownMove:
jmp consumeTheLetter

;اذا كان مركزه عند مضاعفات ال160 لا يكمنه النحرك للشمال
;الصف 160 بايت
CheckArrowLeft:
cmp PlayerPress, 4Bh
jne CheckArrowRight
CheckLeftValidMove:
mov ax, playerPos
mov dl, 160
div dl
mov dl, ah
cmp dl, 0
je DisaproveLeftMove
mov di, playerPos
sub di, BYTE PTR 2
call far ptr MovePlayer
DisaproveLeftMove:
jmp consumeTheLetter

;اذا كان اللاعب عند المركز رقم 158 بايت من اي صف لا يمكن ان نحركه لليمن
;فهنا نحن نطرح من مركز اللاعب 158 و اذا كان الرقم من مضاعفات ال160 فهذا يعني
;انه عند المركز 158 من صفه و لا يجب ان يتحرك
CheckArrowRight:
cmp PlayerPress, 4Dh
jne consumeTheLetter;معناه انه ضغط علي زر ليس من ازرار التحكمات الاربعة و  يجب التخلص
CheckRightValidMove:
mov ax, playerPos
cmp ax, 158
je DisaproveRightMove
cmp ax, 158
jb appproveRightMove
sub ax, 158
mov dl, 160
div dl
mov dl, ah
cmp dl, 0
je DisaproveRightMove
appproveRightMove:
mov di, playerPos
add di, BYTE PTR 2
call far ptr MovePlayer
DisaproveRightMove:


consumeTheLetter:
mov ah,0
int 16h

checkCollisionAfterplayermove:
mov al, collisionDetected
cmp al, 1
jne CHECKYELLOW
int 3
jmp gameOver

CHECKYELLOW:
;نري اذا وصل الاعب للخط الاصفر فاذا كان كذلك
;فانه يجب رسم الصف الاصفر فالناحية الاخري
;و يجب زيادة مجموع
;و يجب تغيير سرعة تحرك المستطيلات
mov ax, playerPos
cmp yellowLinePos, 0
jne YellowIsAtTheButtom
YellowIsAtTheTop:
cmp ax, WORD PTR 320
jb YesHeReachedYellowTop
jmp CheckSpeed ; معناه ان الخط الاصفر فو و اللاعب لم يصل اليه
YesHeReachedYellowTop:
inc gameScore;نزود مجموع اللاعب
;نرسم الخط الاصفر اسفل و نمسح الخط الاصفر من فوق
call far ptr drawYellowLine
jmp CheckSpeed
YellowIsAtTheButtom:
cmp ax, WORD PTR 3840
jae YesHeReachedYellowButtom
jmp CheckSpeed
YesHeReachedYellowButtom:
inc gameScore;نزود مجموع اللاعب
;نرسم الخط الاصفر اعلي و نمسح الخط الاصفر من تحت
call far ptr drawYellowLine

CheckSpeed:
;نرسم اللاعب مرة اخري
call far ptr DrawPlayer
;نزود سرعة المستطيلات بالنسبة للمجموع و ال
;MilliSecSpeed
;عن طريق النسبة بينبه و بين المجموع
;كل ما المجموع يزيد اتنين السرعة تزيد
;يعني اقلل ال MilliSecSpeed
;لغاية م اوصل لواحد
mov al,  gameScore
sub al, lastFourMultipleSCore
cmp al, 02h
jae YESIncreaseSpeed
NODontIncreaseSpeed:
jmp contineGameLoop
YESIncreaseSpeed:
mov al, MilliSecSpeed
cmp al,1
je DontIncreaseAlsoReachecone
dec al
mov MilliSecSpeed, al
DontIncreaseAlsoReachecone:
mov ax, WORD PTR gameScore
mov lastFourMultipleSCore, al
contineGameLoop:
call far ptr drawScore
jmp GameLoop

;ننتظر تصرف من اللاعب اما اعادة اللعبة و اما الخروج منها
gameOver:
call far ptr drawGameOverMsg
gameOverWait:
getDecision:
mov ax, 0
mov ah, 1; ناخذ ضغطة الزر ان وجدت
int 16h
jz getDecision;نري اذا الاعب ضغط زر ام لا
mov playerPress, ah
consumeLetter:
mov ah,0
int 16h
cmp playerPress, 10h
jne checkRetry
jmp exit
checkRetry:
cmp playerPress, 13h
jne gameOverWait
jmp RetryGameSelected

exit:
        MOV AH, 4Ch ; Service 4Ch - Terminate with Error Code
        MOV AL, 0 ; Error code
        INT 21h ; Interrupt 21h - DOS General Interrupts

MAIN    ENDP
;-------------------------------------------------
;-------------------------------------------------
initScene                PROC FAR
;خلفية سوداء فالاول
mov cx,WORD PTR SCREENCELLSCOUNT; عدد الخلايا
mov di,00h;بيشاور علي اول خلية
DrawGreySCREEN:
mov es:[di],BYTE PTR 219; Letter in al
mov es:[di+1],BYTE PTR backgroundColor ;colour
add di, 2
loop DrawGreySCREEN
;بنرسم الخط اللي بيبنا فيه المجموع و الاخطارات
mov cx, WORD PTR 80 ;اول صف يمثل 80 خانة
mov di, 00h;بيشاور علي اول خلية
drawStatusLine:
mov es:[di],BYTE PTR 219; الحرف
mov es:[di+1],BYTE PTR 00 ;اللون
add di, 2
loop drawStatusLine
;نرسم الخط الاصفر الهدف
mov cx, WORD PTR 80 ;اول صف يمثل 80 خانة
mov di, WORD PTR 160 ;بيشاور علي اول خانة في الصف الثاني
drawGoalLineOne:
mov es:[di],BYTE PTR 219; الحرف
mov es:[di+1],BYTE PTR 0Eh ;اللون
add di, 2
loop drawGoalLineOne
;نرسم الخطوط البيضاء اللي فالشارع
call far ptr DrawWhiteStripes
;نرسم عدد معين من المربعات الحمراء الخطر(10 مربعات) في اماكن عشوائية
;و لقد تم تحديد اماكنهم باستخادم كود موجود في
;subProcdure "getCellsPos"
;نفذ مرة واحدة فقط اثناء برمجة اللعبة و لن يتم تنفيذه ابدا (كان فقط لتحديد اماكن عشوائية) عن
;عن طريق الوقت و اخذ باقي القسمة
call far ptr DrawRedCells
; نرسم اللاعب الي هو عبارة عن خلية زرقاء اللون
call far ptr DrawPlayer
;ضبط الوقت عن طريق حفظ الوقت (الثواني
;و واحد علي مائة من الثانية) لاسنخدامهما في تحريك الخلايا الحمراء المميتة
call far ptr initTimer
ret
initScene                ENDP
;-------------------------------------------------
;-------------------------------------------------
drawSingleStripe                PROC FAR
;بترسم خط واحد من الخطوط البيضاء
push cx
push bx;بنحفظه علاشن احنا بنزود عليه هنا الحد المسموح بيه لرسم الخط الابيض لكل صف
mov cx, 8 ;عدد الخلايا لكل خط ابيض(طول الخط) 8 خلايا
add bx, 154;نقطة النهاية فالصف
drawSingleStripeLoop:
cmp di, bx
jae exitDSS
mov es:[di],BYTE PTR 219; الحرف
mov es:[di+1],BYTE PTR 0fh ;اللون الابيض علي خلفية سوداء
add di, 2h
loop drawSingleStripeLoop
exitDSS:
pop bx
pop cx
ret
drawSingleStripe                ENDP
;-------------------------------------------------
;-------------------------------------------------
;بترسم المربع في اربع خلايا و النقطة موجود فال
;register di
drawSquare                PROC FAR
mov es:[di],BYTE PTR 178; الحرف
mov es:[di+1],BYTE PTR 0Ch ;اللون
mov es:[di+2],BYTE PTR 178; الحرف
mov es:[di+3],BYTE PTR 0Ch ;اللون
mov es:[di+4],BYTE PTR 178; الحرف
mov es:[di+5],BYTE PTR 0Ch ;اللون
mov es:[di+6],BYTE PTR 178; الحرف
mov es:[di+7],BYTE PTR 0Ch ;اللون
ret
drawSquare                ENDP
;-------------------------------------------------
;-------------------------------------------------
drawScore                PROC FAR
;بنرسم المجموع
push ax
push bx
;هنا نقسم المجموع علي 10 مع العلم ان اعلي مجموع في هذه اللعبة هو 99
mov ah, 0 ;بنصفره
mov al, gameScore
mov bl, BYTE PTR 10
div bl
add ah, '0';نضيف الاسكيي بتاع الصفر
add al, '0'
mov es:[0], BYTE PTR 'S' ; الحرف
mov es:[1], BYTE PTR 0Ah ;اللون الاخضر علي خلفية سوداء
mov es:[2], BYTE PTR 'C' ; الحرف
mov es:[3], BYTE PTR 0Ah ;اللون الاخضر علي خلفية سوداء
mov es:[4], BYTE PTR 'O' ; الحرف
mov es:[5], BYTE PTR 0Ah ;اللون الاخضر علي خلفية سوداء
mov es:[6], BYTE PTR 'R' ; الحرف
mov es:[7], BYTE PTR 0Ah ;اللون الاخضر علي خلفية سوداء
mov es:[8], BYTE PTR 'E' ; الحرف
mov es:[9], BYTE PTR 0Ah ;اللون الاخضر علي خلفية سوداء
mov es:[10], BYTE PTR ':' ; الحرف
mov es:[11], BYTE PTR 0Ah ;اللون الاخضر علي خلفية سوداء
mov es:[12], BYTE PTR ' ' ; الحرف
mov es:[13], BYTE PTR 0Ah ;اللون الاخضر علي خلفية سوداء
mov es:[14], al ;الرقم الاكبر للمجموع
mov es:[15], BYTE PTR 0Ah ;اللون الاخضر علي خلفية سوداء
mov es:[16], ah;الرق الاصغر للمجموع
mov es:[17], BYTE PTR 0Ah ;اللون الاخضر علي خلفية سوداء
;جملة الخروج quit Message
mov es:[108], BYTE PTR 'Q' ; الحرف
mov es:[109], BYTE PTR 0Ah ;اللون الاخضر علي خلفية سوداء
mov es:[110], BYTE PTR ':' ; الحرف
mov es:[111], BYTE PTR 0Ah ;اللون الاخضر علي خلفية سوداء
mov es:[112], BYTE PTR 'Q' ; الحرف
mov es:[113], BYTE PTR 0Ah ;اللون الاخضر علي خلفية سوداء
mov es:[114], BYTE PTR 'U' ; الحرف
mov es:[115], BYTE PTR 0Ah ;اللون الاخضر علي خلفية سوداء
mov es:[116], BYTE PTR 'I' ; الحرف
mov es:[117], BYTE PTR 0Ah ;اللون الاخضر علي خلفية سوداء
mov es:[118], BYTE PTR 'T' ; الحرف
mov es:[119], BYTE PTR 0Ah ;اللون الاخضر علي خلفية سوداء
;Retry Messaeg
mov es:[126], BYTE PTR 'R' ; الحرف
mov es:[127], BYTE PTR 0Ah ;اللون الاخضر علي خلفية سوداء
mov es:[128], BYTE PTR ':' ; الحرف
mov es:[129], BYTE PTR 0Ah ;اللون الاخضر علي خلفية سوداء
mov es:[130], BYTE PTR 'R' ; الحرف
mov es:[131], BYTE PTR 0Ah ;اللون الاخضر علي خلفية سوداء
mov es:[132], BYTE PTR 'E' ; الحرف
mov es:[133], BYTE PTR 0Ah ;اللون الاخضر علي خلفية سوداء
mov es:[134], BYTE PTR 'T' ; الحرف
mov es:[135], BYTE PTR 0Ah ;اللون الاخضر علي خلفية سوداء
mov es:[136], BYTE PTR 'R' ; الحرف
mov es:[137], BYTE PTR 0Ah ;اللون الاخضر علي خلفية سوداء
mov es:[138], BYTE PTR 'Y' ; الحرف
mov es:[139], BYTE PTR 0Ah ;اللون الاخضر علي خلفية سوداء
pop bx
pop ax
ret
drawScore                ENDP
;-------------------------------------------------
;-------------------------------------------------
drawGameOverMsg                PROC FAR
;بترسم رسالة الخسارة
mov es:[68], BYTE PTR 'G' ; الحرف
mov es:[69], BYTE PTR 0Ch ;اللون الاحمر علي خلفية سوداء
mov es:[70], BYTE PTR 'A'; الحرف
mov es:[71], BYTE PTR 0Ch ;اللون الاحمر علي خلفية سوداء
mov es:[72], BYTE PTR 'M'; الحرف
mov es:[73], BYTE PTR 0Ch;اللون الاحمر علي خلفية سوداء
mov es:[74], BYTE PTR 'E'; الحرف
mov es:[75], BYTE PTR 0Ch;اللون الاحمر علي خلفية سوداء
mov es:[76], BYTE PTR ' '; الحرف
mov es:[77], BYTE PTR 0Ch;اللون الاحمر علي خلفية سوداء
mov es:[78], BYTE PTR 'O'; الحرف
mov es:[79], BYTE PTR 0Ch;اللون الاحمر علي خلفية سوداء
mov es:[80], BYTE PTR 'V'; الحرف
mov es:[81], BYTE PTR 0Ch;اللون الاحمر علي خلفية سوداء
mov es:[82], BYTE PTR 'E'; الحرف
mov es:[83], BYTE PTR 0Ch;اللون الاحمر علي خلفية سوداء
mov es:[84], BYTE PTR 'R'; الحرف
mov es:[85], BYTE PTR 0Ch;اللون الاحمر علي خلفية سوداء
mov es:[86], BYTE PTR ' '; الحرف
mov es:[87], BYTE PTR 0Ch;اللون الاحمر علي خلفية سوداء
mov es:[88], BYTE PTR ':'; الحرف
mov es:[89], BYTE PTR 0Ch;اللون الاحمر علي خلفية سوداء
mov es:[90], BYTE PTR '('; الحرف
mov es:[91], BYTE PTR 0Ch;اللون الاحمر علي خلفية سوداء
ret
drawGameOverMsg                ENDP
;-------------------------------------------------
;-------------------------------------------------
DrawRedCells                PROC FAR
mov cx, 15;15 واحدة
mov bx, offset redTilessPos;نضع عنوان اول مركز للمستطيلات الحمراء
drawDeathRedCells:
mov di, [bx]; نضعه في هذا المكان لأن الدالة التاليه تستخدمه
call far ptr drawSquare
; add di, WORD PTR 160
add bx,BYTE PTR 2
loop drawDeathRedCells
; loop drawRandomRedDeathCells
ret
DrawRedCells                ENDP
;-------------------------------------------------
;-------------------------------------------------
DrawWhiteStripes                PROC FAR
;نرسم الخطوط البيضاء اللي فالشارع
;هما موجودين في الصفوف الفردية
mov cx, BYTE PTR 17 ;عدد الصفوف الفردية
mov bx, 486;المكان الابتدائي لاول خط ابيض في الصف رقم 4
mov di, bx;ننقل نقطة البداية
drawStripes:
mov dx, BYTE PTR 5;عدد الخطوط البيضاء فالصف
drawRowStripes:
call far ptr drawSingleStripe
add di, BYTE PTR 18;المسافة بين خطين فالصف
dec dx
jnz drawRowStripes
add bx, WORD PTR 3C0h;نزود الفرف بين الصفين اللي فيهم الخطوط البيضاء
mov di,  bx;ننقل المركز الجديد
loop drawStripes
ret
DrawWhiteStripes                ENDP
;-------------------------------------------------
;-------------------------------------------------
DrawPlayer                PROC FAR
;نرسم اللاعب
push di;نحفظ القيمة الموجودة لكي نتجنب حدوث اي نتيجة غير متوقعة في البرنامج
mov di, playerPos
mov es:[di],BYTE PTR 219; الحرف
mov es:[di+1],BYTE PTR 01h ;اللون الازرق علي اسود
pop di
ret
DrawPlayer                ENDP
;-------------------------------------------------
;-------------------------------------------------
;نحرك المستطيلات الحمراء
MoveAllTiles               PROC far
mov cx, 15;عددهم
MovingAllTiles:
mov bx, offset redTilessPos ; عنوان مراكز المستطيلات
mov ax, 15; عايزين نشاور علي اول واحد
sub ax, cx; فبنطرح
; 15-cx
add bx, ax; بنجمع مرتين علشان ورد = 2 بايتس
add bx, ax
mov di, offset redTilesMovement ;بنجيب كل مستطيل هيمشي قد ايه
add di, ax
add di, ax
mov dx, [bx]
add dx, [di]; نحسب المركز الجديد = المركز الحالي + مقدار الحركة
;بنقارن مركز المستطيل الاحمر بحدود الصف لو طلع براها ميتحركش و يعكس اتجاه الحركة
checkLowBoundaries:
mov si, offset redTilesLowLimits;موجود الحدود لكل مستطيل فيه (الحدود الصغري)
add si, ax
add si, ax
cmp dx, ds:[si]
jae checkHightBoundaries
jmp FailedBoundariesCheck
checkHightBoundaries:
mov si, offset redTilesHighLimits;بنجيب الحود الكبري و نشوف المركز فال رينج و لا لأ
add si, ax
add si, ax
cmp dx, ds:[si]
jb PassedBoundariesCheck
jmp FailedBoundariesCheck
PassedBoundariesCheck:;المركز موجود فالحدود يبقي نحركه
call far ptr moveSingleTile
FailedBoundariesCheck:;بره الحدود
;نعكس الاتجاه
mov ax, 0 ;الاتجاه الجديد = 0 - مقدار الحركة الحالي = -مقدار الحركة الحالي
sub ax, ds:[di]
mov ds:[di], ax
ContinueMovingAlliles:
dec cx
jz returnMovingAllTiles
jmp MovingAllTiles
returnMovingAllTiles:
                    RET
MoveAllTiles               ENDP
;-------------------------------------------------
;-------------------------------------------------
moveSingleTile               PROC far
mov di, [bx];مكان المستطيل قبل التغيير
;رسم لون الخلفية فالمكان الحالي
mov es:[di],BYTE PTR 219; الحرف
mov es:[di+1],BYTE PTR backgroundColor ;لون الخلفية
mov es:[di+2],BYTE PTR 219; الحرف
mov es:[di+3],BYTE PTR backgroundColor ;لون الخلفية
mov es:[di+4],BYTE PTR 219; الحرف
mov es:[di+5],BYTE PTR backgroundColor ;لون الخلفية
mov es:[di+6],BYTE PTR 219; الحرف
mov es:[di+7],BYTE PTR backgroundColor ;لون الخلفية
mov [bx], dx;وضع المركز الجديد بعد التغيير
mov di, [bx];ننادي علي رسم المستطيل فالمكان الجديد
call far ptr drawSquare
                    RET
moveSingleTile               ENDP
;-------------------------------------------------
;-------------------------------------------------
;بتحسب الوقت الحالي
initTimer                PROC    FAR
                    mov ah,2Ch
                    int 21h
                    mov currentDeciSec, dl;نحفظ الجزء علي مائة من الثانية
                    mov currentSec, dh;نحفظ الثانية الحالية
                    RET
initTimer                ENDP
;-------------------------------------------------
;-------------------------------------------------
MovePlayer                PROC FAR
;نعمل تاكيد علي عدم التصادم
mov al, es:[di+1]
cmp al, 0Ch
jne NOCOLLISION
mov collisionDetected, 1
NOCOLLISION:
mov si, playerPos;نضع مكان اللاعب
mov al, 1;نضع رقم 1 لنقارن به
cmp playerWasOnWhiteTile, 1; نعرف اذا كان اللاعب كان موجود علي خلية لونها ابيض و لا لون الخلفية العادي
je drawWhiteBackgnd
drawNormalBackgnd:;اذا كان لون الخلفية
mov es:[si],BYTE PTR 219; الحرف
mov es:[si+1],BYTE PTR backgroundColor
jmp cont
drawWhiteBackgnd:;اذا كان اللون الابيض
mov es:[si],BYTE PTR 219; الحرف
mov es:[si+1],BYTE PTR 0Fh
cont:
mov playerWasOnWhiteTile, 0; نرجعه لصفر(يعني كان واقف علي لون الخلفية) الي ان يثبت العكس
; نشوف المكان الجديد اللي هيقف عليه ابيض و لا لأ
mov al, es:[di+1]
cmp al, 0Fh
jne NotAWhite
mov playerWasOnWhiteTile, 1
NotAWhite:
;نرسم اللاعب
mov es:[di],BYTE PTR 219; الحرف
mov es:[di+1],BYTE PTR 01h ;اللون الازرق علي اسود
mov playerPos, di;نحفظ المركز الجديد
ret
MovePlayer                ENDP
;-------------------------------------------------
;بتحسب الوقت الحالي
drawYellowLine                PROC    FAR
;نقارن اذا كان الخط الاصفر فوق ام تحت
cmp yellowLinePos, 0
jne ItsAtButtom
ItsAtTop:
mov si, WORD PTR 160 ;بنحط فيه مكان الخط الاصفر القديم (اول خانة)
mov di, WORD PTR 3840 ;بنحط فيه مكان الخط الاصفر الجديد (اول خانة)
mov yellowLinePos, 1;نجعل الخط الاصفر تحت
jmp REMOVWDRAWYELLOW
ItsAtButtom:
mov si, WORD PTR 3840 ;بنحط فيه مكان الخط الاصفر القديم (اول خانة)
mov di, WORD PTR 160 ;بنحط فيه مكان الخط الاصفر الجديد (اول خانة)
mov yellowLinePos, 0;نجعل الخط الاصفر فوق
REMOVWDRAWYELLOW:
;نسرم مكانه لون الخلفية
mov cx, WORD PTR 80 ;اي صف يمثل 80 خانة
RemoveYellow:
mov es:[si],BYTE PTR 219; الحرف
mov es:[si+1],BYTE PTR backgroundColor ;اللون
add si, 2
loop RemoveYellow
;نرسم الخط الاصفر فالمكان الجديد
mov cx, WORD PTR 80 ;اي صف يمثل 80 خانة
drawYellow:
mov es:[di],BYTE PTR 219; الحرف
mov es:[di+1],BYTE PTR 0Eh ;اللون
add di, 2
loop drawYellow
                    RET
drawYellowLine                ENDP
;-------------------------------------------------
getCellsPos                PROC    FAR
mov di, 480;بداية اول مكان مستطيل احمر
mov cx, 15 ;15 مربع
;بجيب بطريقة عشوائية  باقي الاماكن
push cx
mov ah, 2CH
int 21h;بجيب الوت
pop cx
GetRandomRedDeathCells:
cmp dx, WORD PTR 160;بنقارن الوقت المكون من الثواني + الجزء من المائ من الثواني بحدود الشاشة
jb itsinRowRange; و لو الرقم بره الحدود نضبطه
itsAboveRange:
mov dx, ax
mov bl, BYTE PTR 160
div bl
mov ah, 0h
mov dx, ax
itsinRowRange:
test dx, 00000001b;و بنشوف انه لو مش رقم زوجي لازم نخليه زوجي
jz itsEvenContinueItsOK
itsOddMakeitEven:
and dx, 11111110b;بنخليه زوجي
itsEvenContinueItsOK:
add di,dx
;نحفظ مكان المستطيل
mov bx, 15
sub bx, cx
mov ax, bx
add bx, ax; word x2byte
add bx, offset redTilessPos
mov ds:[bx], di
add di, WORD PTR 160;بننقل علي الصف اللي بعده
loop GetRandomRedDeathCells
                    RET
getCellsPos                ENDP
;-------------------------------------------------
RetryGameInitializations                PROC    FAR
;نرجع تاني الاماكن الابتدائية للمستطيلات
mov cx, 15
mov di, offset initialTilesPos
mov si, offset redTilessPos
reInitializeGamePos:
mov ax, [di]
mov [si], ax
add di, 2
add si, 2
loop reInitializeGamePos
;نرجع الباقي زي الاول
mov playerPos, 3920
mov playerWasOnWhiteTile, 0
mov yellowLinePos, 0h
mov MilliSecSpeed, 6
mov lastFourMultipleSCore, 0
mov gameScore, 0
mov collisionDetected, 0
RET
RetryGameInitializations                ENDP
;-------------------------------------------------
;-------------------------------------------------
;-------------------------------------------------
END MAIN
