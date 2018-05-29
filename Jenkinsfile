pipeline {
  agent any
  stages {
    stage('Awesome stage') {
      parallel {
        stage('Awesome stage') {
          when {
                expression {
                    GIT_BRANCH = 'origin/' + sh(returnStdout: true, script: 'git rev-parse --abbrev-ref HEAD').trim()
                    return true
                }
            }
          steps {
            echo 'Hello World'
            waitUntil() {
              sleep 1
            }

          }
        }
        stage('Cool Stage') {
          steps {
            sleep 2
          }
        }
      }
    }
    stage('myStage') {
      steps {
        timestamps()
      }
    }
  }
}
