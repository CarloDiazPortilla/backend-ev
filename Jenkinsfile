@Library('shared-lib') _

pipeline {
    agent any

    parameters {
        string(name: 'SERVER_IP', defaultValue: '3.137.175.226', description: 'IP pública del servidor')
    }

    environment {
        IMAGE = 'carlodiazpor/backend-ev'
    }

    stages {
        stage('Build & Push') {
            steps {
                script { env.TAG = buildAndPush(image: env.IMAGE) }
            }
        }
        stage('Deploy') {
            steps {
                deployToServer(host: params.SERVER_IP, tag: env.TAG, composeFile: 'docker-compose.prod.yml')
            }
        }
        stage('Smoke test') {
            steps {
                smokeTest(host: params.SERVER_IP, path: '/users')
            }
        }
    }

    post {
        success { echo "Desplegado: http://${params.SERVER_IP}:3000" }
        failure { echo 'El pipeline falló, revisa la etapa marcada en rojo' }
    }
}