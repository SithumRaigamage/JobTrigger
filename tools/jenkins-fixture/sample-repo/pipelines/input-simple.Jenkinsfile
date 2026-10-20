// US-PIPE-05: a parameterless input step (proceedEmpty / abort).
pipeline {
  agent none
  stages {
    stage('Approve') {
      steps {
        input message: 'Promote to staging?', ok: 'Promote', id: 'PromoteGate'
      }
    }
    stage('Promote') {
      steps { echo 'Promoted' }
    }
  }
}
