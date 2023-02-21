pipeline {
    agent any
    environment{
        NEXUS_IP='nexus'
        STG_IP='localhost'
        PROD_IP='192.168.33.85'
        NEXUS_REPO='word-cloud-build'
        BRANCH='pipeline'
    }
    stages {
        stage('Download Git repo') {
            steps {
                git 'https://github.com/mkolchyn/word-cloud-generator.git'
            }
        }
        stage('Pre-build tests') {
            agent {
                docker { 
                    image 'golang:1.16'
                    reuseNode true
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
//             tools{
//                 go 'go 1.16'
//             }
            steps {
                sh '''
                  pwd
                  make lint
                  make test'''
            }
        }
        stage('Build in Docker container') {
            agent {
                docker { 
                    image 'golang:1.16'
                    reuseNode true
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                sh '''
                    sed -i "s/1.DEVELOPMENT/1.${BUILD_NUMBER}/g" static/version
                    CGO_ENABLED=0 GOOS=linux GOCACHE=/tmp/ go build -a -installsuffix cgo -o artifacts/word-cloud-generator -v
                    gzip -f artifacts/word-cloud-generator'''
            }
        }
        stage('Upload artifact to Nexus') {
            steps {
                nexusArtifactUploader(
                    nexusVersion: 'nexus3',
                    protocol: 'http',
                    nexusUrl: "${NEXUS_IP}:8081",
                    groupId: "${BRANCH}",
                    version: "1.${BUILD_NUMBER}",
                    repository: "${NEXUS_REPO}",
                    credentialsId: 'nexus-creds',
                    artifacts: [
                        [artifactId: 'word-cloud-generator',
                         classifier: '',
                         file: './artifacts/word-cloud-generator.gz',
                         type: 'gz']
                    ]
                )
            }
        }
        stage('Tests in Docker container') {
            stages {
                stage('Download artifact from Nexus'){
                    steps{
                        withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASSWORD')]) {
                            sh '''
                            mkdir -p ./staging
                            curl -X GET http://${NEXUS_IP}:8081/repository/${NEXUS_REPO}/${BRANCH}/word-cloud-generator/1.${BUILD_NUMBER}/word-cloud-generator-1.${BUILD_NUMBER}.gz --user ${NEXUS_USER}:${NEXUS_PASSWORD} -o ./staging/word-cloud-generator.gz
                            gunzip -f ./staging/word-cloud-generator.gz
                            chmod +x ./staging/word-cloud-generator'''
                        }
                    }
                }
                // stage('Deploy test version on Docker container'){
                //     agent { 
                //         dockerfile {
                //             filename 'Dockerfile'
                //             args '-p 8888:8888'
                //             args '-d'
                //             reuseNode true
                //         }
                //     }
                //     steps {
                //         sh '/word-cloud-generator'
                //     }
                // }
                stage('Parallel testing') {
                    parallel {
                        stage('Parallel testing - Deploy docker container'){
                            agent { 
                                dockerfile {
                                    filename 'Dockerfile'
                                    args '-p 8888:8888 --name staging -v /var/run/docker.sock:/var/run/docker.sock'
                                    reuseNode true
                                }
                            }
                            steps {
                                sh '/word-cloud-generator'
                            }
                        }
                        stage('Parallel testing - Tests'){
                            steps{
                                sh '''res=`curl -s -H "Content-Type: application/json" -d '{"text":"ths is a really really really important thing this is"}' http://${STG_IP}:8888/version | jq '. | length'`
                                      if [ "1" != "$res" ]; then
                                        exit 99
                                      fi
                                      
                                      res=`curl -s -H "Content-Type: application/json" -d '{"text":"ths is a really really really important thing this is"}' http://${STG_IP}:8888/api | jq '. | length'`
                                      if [ "7" != "$res" ]; then
                                        exit 99
                                      fi'''
                            }
                        }
                        stage('Parallel testing - Stage 2'){
                            steps{
                                sh '''res=`curl -s -H "Content-Type: application/json" -d '{"text":"ths is a really really really important thing this is"}' http://${STG_IP}:8888/version | jq '. | length'`
                                      if [ "1" != "$res" ]; then
                                        exit 99
                                      fi
                                      
                                      res=`curl -s -H "Content-Type: application/json" -d '{"text":"ths is a really really really important thing this is"}' http://${STG_IP}:8888/api | jq '. | length'`
                                      if [ "7" != "$res" ]; then
                                        exit 99
                                      fi'''
                            }
                        }
                    }
                }
            }
        }
    }
}
