@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: 화면 초기화 및 이름 입력 받기
:input_name
cls
echo ==================================================
echo            BWYF 사무실 컴퓨터 정보 확인 도구
echo ==================================================
echo.
set /p user_name="▶ 현재 PC 사용자 본인의 이름을 입력해 주세요 (예: 서원하) : "

:: 이름 입력 예외 처리 (그냥 엔터 쳤을 때 방지)
if "%user_name%"=="" (
    echo.
    echo ❌ 이름을 입력하셔야 진행할 수 있습니다.
    timeout /t 2 >nul
    goto input_name
)

echo.
echo %user_name% 님의 PC 정보를 안전하게 검색 중입니다. 잠시만 기다려주세요...
echo.

:: 1. 컴퓨터 이름 추출
set "pc_name=%COMPUTERNAME%"

:: 2. 내부 IP (사설 IP) 추출
set "internal_ip="
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do (
    set "internal_ip=%%a"
)
set "internal_ip=!internal_ip: =!"

:: 3. 외부 IP (공인 IP) 추출 (응답 없을 시 2초 만에 타임아웃 처리)
set "external_ip="
for /f "delims=" %%a in ('curl -s -m 2 https://api.ipify.org') do (
    set "external_ip=%%a"
)
set "external_ip=!external_ip: =!"

:: 4. IP 할당 방식 (고정/유동) 진단 - 보안 프로그램 우회(순수 ipconfig 파싱)
set "last_dhcp="
set "dhcp_result=확인 불가"
for /f "delims=" %%L in ('ipconfig /all') do (
    set "line=%%L"
    
    :: 'DHCP' 단어가 포함된 줄을 기억
    if "!line:DHCP=!" neq "!line!" (
        set "last_dhcp=!line!"
    )
    
    :: 내 IP 주소가 있는 줄을 찾으면 직전 DHCP 상태 확정
    if "!internal_ip!" neq "" (
        if "!line:%internal_ip%=!" neq "!line!" (
            if "!last_dhcp:아니=!" neq "!last_dhcp!" set "dhcp_result=STATIC"
            if "!last_dhcp:No=!" neq "!last_dhcp!" set "dhcp_result=STATIC"
            if "!last_dhcp:예=!" neq "!last_dhcp!" set "dhcp_result=DHCP"
            if "!last_dhcp:Yes=!" neq "!last_dhcp!" set "dhcp_result=DHCP"
        )
    )
)

:: 할당 방식 결과 및 안내문 매핑
if "!dhcp_result!"=="DHCP" (
    set "ip_type=유동 IP(자동)"
    set "description=└─ 사내 전산망 규칙에 따라 수동으로 IP가 고정되지 않은 상태입니다."
) else if "!dhcp_result!"=="STATIC" (
    set "ip_type=고정 IP(수동)"
    set "description=└─ 사내 전산망 규칙에 따라 수동으로 IP가 고정된 상태입니다."
) else (
    set "ip_type=확인 불가"
    set "description=└─ 알 수 없는 네트워크 구조입니다."
)

:: 빈 값 예외 처리
if "!pc_name!"=="" set "pc_name=확인 불가"
if "!internal_ip!"=="" set "internal_ip=확인 불가"
if "!external_ip!"=="" set "external_ip=확인 불가"

:: 5. 클립보드에 병합된 정보 자동 복사
set "target_info=사용자명(PC 이름): %user_name%(!pc_name!) / 방식: !ip_type! / 내부 IP: !internal_ip! / 외부 IP: !external_ip!"
<nul set /p="!target_info!"| clip

:: 진단 결과 화면 출력
cls
echo ==================================================
echo          BWYF 사무실 컴퓨터 정보 확인 완료
echo ==================================================
echo.
echo  ▶ 사 용 자 : %user_name%
echo  ▶ P C 이 름: !pc_name!
echo  ▶ 할당 방식: !ip_type!
echo     !description!
echo  ▶ 내 부 I P: !internal_ip!
echo  ▶ 외 부 I P: !external_ip!
echo.
echo ==================================================
echo ✅ 아래의 정보가 클립보드에 자동 복사되었습니다!
echo.
echo    [!target_info!]
echo.
echo    전산 담당자에게 제출 할 입력창에 마우스 우클릭 후 '붙여넣기'(Ctrl+V) 하세요.
echo ==================================================
echo.
echo ▶ 아무 키나 누르면 프로그램이 종료됩니다...
pause >nul
exit /b