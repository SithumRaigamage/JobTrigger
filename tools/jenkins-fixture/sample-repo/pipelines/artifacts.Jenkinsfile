// US-PIPE-07 / AUD-21: many small artifacts, a nested path containing a
// space, and one 60 MB artifact.
pipeline {
  agent any
  stages {
    stage('Package') {
      steps {
        sh '''
          rm -rf out && mkdir -p out/sub
          for i in $(seq 1 25); do echo "artifact $i" > "out/file-$i.txt"; done
          echo nested > "out/sub/with space.txt"
          head -c 60000000 /dev/urandom > out/large.bin
        '''
        archiveArtifacts artifacts: 'out/**'
      }
    }
  }
}
