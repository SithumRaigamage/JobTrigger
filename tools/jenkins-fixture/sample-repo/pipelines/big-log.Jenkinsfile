// US-JX-07 / P5-13: a 50,000-line log with ANSI colors, Timestamper
// timestamps, and error markers for "jump to first error".
pipeline {
  agent any
  options {
    timestamps()
    ansiColor('xterm')
  }
  stages {
    stage('Log') {
      steps {
        sh '''
          i=1
          while [ $i -le 50000 ]; do
            if [ $i -eq 30000 ]; then
              printf '\\033[1;31mERROR\\033[0m: fixture failure marker at line %s\\n' "$i"
            else
              printf '\\033[32mINFO\\033[0m  line %s \\033[2m(dim)\\033[0m\\n' "$i"
            fi
            i=$((i + 1))
          done
        '''
      }
    }
  }
}
