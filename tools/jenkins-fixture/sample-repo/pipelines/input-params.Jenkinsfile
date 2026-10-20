// US-PIPE-05: an input step with parameters (submit), including a password
// parameter (US-JX-01 masking applies to input steps too).
pipeline {
  agent none
  stages {
    stage('Approve') {
      steps {
        script {
          def answer = input(
            message: 'Deploy to production?',
            ok: 'Deploy',
            id: 'DeployGate',
            parameters: [
              string(name: 'VERSION', defaultValue: '1.2.3', description: 'Version to deploy'),
              choice(name: 'REGION', choices: ['eu-west-1', 'us-east-1'], description: 'Target region'),
              password(name: 'OTP', defaultValue: '', description: 'One-time password'),
            ]
          )
          // Never echo the password parameter.
          echo "Deploying ${answer.VERSION} to ${answer.REGION}"
        }
      }
    }
  }
}
