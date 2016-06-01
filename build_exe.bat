@ECHO OFF
IF [%1] == [] GOTO no_lang

ECHO ON
ocra --gem-minimal --icon src/res/app.ico --no-lzma --windows --output build/ets2sync_helper_%1.exe --chdir-first src/ets2sync_helper.rb src/res/* -- %1
@ECHO OFF
GOTO :eof

:no_lang
ECHO No language specified. Please pass the language as a command-line argument. E.g:
ECHO     build_exe pt-BR
