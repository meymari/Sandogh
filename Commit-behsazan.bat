REM \\storage.behsazan.local\meymari\PortableGit\bin\git config --system http.sslverify false
REM \\storage.behsazan.local\meymari\PortableGit\bin\git -C \\storage.behsazan.local\meymari\Sandogh clone https://github.com/meymari/Sandogh.git
REM pause
\\storage.behsazan.local\meymari\PortableGit\bin\git -C \\storage.behsazan.local\meymari\Sandogh status
\\storage.behsazan.local\meymari\PortableGit\bin\git -C \\storage.behsazan.local\meymari\Sandogh add "Sandogh.exe"
\\storage.behsazan.local\meymari\PortableGit\bin\git -C \\storage.behsazan.local\meymari\Sandogh add "DB.mdb"
\\storage.behsazan.local\meymari\PortableGit\bin\git -C \\storage.behsazan.local\meymari\Sandogh add -A
\\storage.behsazan.local\meymari\PortableGit\bin\git -C \\storage.behsazan.local\meymari\Sandogh commit -m "At Behsazan"
\\storage.behsazan.local\meymari\PortableGit\bin\git -C \\storage.behsazan.local\meymari\Sandogh push -u origin master
pause
