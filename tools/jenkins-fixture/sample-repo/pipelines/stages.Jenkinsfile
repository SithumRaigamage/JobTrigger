// US-PIPE-04 / US-JX-04: sequential stages, a parallel stage with one
// failing branch, and a stage that never runs because of that failure.
pipeline {
  agent any
  stages {
    stage('Build') {
      steps { echo 'Compiling...' }
    }
    stage('Test') {
      parallel {
        stage('Unit') {
          steps { echo 'Unit tests passed' }
        }
        stage('Integration') {
          steps {
            echo 'Running integration tests'
            error('Fixture: integration suite failed')
          }
        }
      }
    }
    stage('Deploy') {
      steps { echo 'never reached' }
    }
  }
}
