// US-PIPE-09: triggers `downstream-freestyle`, so that build carries an
// upstream cause pointing back here.
pipeline {
  agent any
  stages {
    stage('Trigger downstream') {
      steps { build job: 'downstream-freestyle', wait: false }
    }
  }
}
