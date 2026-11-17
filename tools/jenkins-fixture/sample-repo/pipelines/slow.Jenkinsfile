// US-JOB-04/05, US-JX-09: a long-running build for polling, cancel, and
// queue tests (two concurrent triggers queue behind each other).
pipeline {
  agent any
  options { disableConcurrentBuilds() }
  stages {
    stage('Work') {
      steps {
        echo 'Working for 90 seconds'
        sleep time: 90, unit: 'SECONDS'
      }
    }
  }
}
