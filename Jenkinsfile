pipeline {
  agent any 

  environment {
      DOCKER_REGISTRY = "docker.io"
      DOCKER_IMAGE = "emmanuelokose/tooling-app"
      COMPOSE_FILE = "tooling.yaml"
  }

  parameters {
    string(name: 'BRANCH_NAME', defaultValue: 'main', description: 'Branch name to build on')
  }

  stages {
    stage ("Initial Cleanup") {
      steps {
        dir ("${WORKSPACE}") {
          deleteDir()
        }
      }
    }

    stage ("Source Code Checkout") {
      steps {
        script {
          // Dynamically determine the branch to checkout based on the parameter
          checkout([
            $class: 'GitSCM',
            branches: [[name: "${params.BRANCH_NAME}"]],
            userRemoteConfigs: [[url: "https://github.com/Kosenuel/MTC2D_Tooling.git"]]
          ])
        }
      }
    }

    stage ("Build Docker Image") {
      steps {
        script {
          def branchName = params.BRANCH_NAME
          env.TAG_NAME = branchName == 'main' ? 'latest' : "${branchName}-0.0.$P{env.BUILD_NUMBER}"

          // Have docker compose build the Docker image using the Dynamic tag (based on the branch name)
          sh "docker-compose -f ${COMPOSE_FILE} build"
        }
      }
    }

    stage ("Run Docker Compose (Startup Image for Integration Test)") {
      steps {
        script {
          // Start the Docker container using the Docker Compose file
          sh "docker-compose -f ${COMPOSE_FILE} up -d"
        }
      }
    }

    stage ("Testing the Application - Availability") {
      steps {
        script {
          def response
          retry(5) {
            sleep(time: 30, unit: 'SECONDS')
            response = sh(script: "curl -s -o /dev/null -w '%{http_code}' http://localhost:5001", returnStdout: true).trim()
            echo "HTTP Status Code is: ${response}"
            if (response == "200") {
              echo "Application is up and running"
            } else {
              error "Application is not available. error code: ${response}"
            }
          }
        }
      }
    }

    stage ("Tag and Push Docker Image to Registry") {
      steps {
        script {
          // Tag the Docker image with the Docker Registry and push it to the registry
          withCredentials([usernamePassword(credentialsId: 'docker-credentials', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
            sh """
              echo "\$PASSWORD" | docker login -u "\$USERNAME" --password-stdin ${DOCKER_REGISTRY}
              docker tag mtc2d_tooling_main-tooling_frontend ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${env.TAG_NAME}
              docker push ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${env.TAG_NAME}
              """
          }
        }
      }
    }

    stage ("Stop the Docker Containers") {
      steps {
        script {
          // Stop the Docker container using the Docker Compose file
          sh "docker-compose -f ${COMPOSE_FILE} down"
        }
      }
    }

    stage ("Final Cleanup") {
      steps {
        script {
          // Cleanup the workspace - Remove Docker images to save space
          sh """
          docker rmi ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${env.TAG_NAME} || true 
          docker rmi tooling-app-cont_main-frontend || true
          """
        }
      }
    }
  }

  // Post Build Actions
  post {
    always {
      script {
        // Logout from Docker
        sh "docker logout"
      }
    }
  }
}
