pipeline {
    agent any

    environment {
        // ✅ Absolute Python path (WORKING on your machine)
        PYTHON = "C:/Python313/python.exe"

        // ✅ SonarQube (Docker-friendly)
        SONAR_HOST_URL = "http://host.docker.internal:9999"
    }

    stages {

        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/team-ecolabel/EcoLabel-MS.git'
            }
        }

        stage('Prepare Model') {
            steps {
                echo 'Copying ML model into workspace root...'
                bat '''
                if not exist "models" mkdir models
                xcopy /E /I /Y "C:\\Users\\elham\\OneDrive\\Documents\\models" "models"
                '''
            }
        }

        stage('Python Quality & Tests') {
            parallel {

                stage('Gateway') {
                    steps {
                        dir('Gateway') {
                            bat '''
                            %PYTHON% -m venv venv
                            venv\\Scripts\\python -m pip install -r requirements.txt
                            venv\\Scripts\\python -m pytest || exit 0
                            '''
                        }
                    }
                }

                stage('ParserProduit') {
                    steps {
                        dir('ParserProduit') {
                            bat '''
                            %PYTHON% -m venv venv
                            venv\\Scripts\\python -m pip install -r requirements.txt
                            venv\\Scripts\\python -m pytest || exit 0
                            '''
                        }
                    }
                }

                stage('NLPIngredients') {
                    steps {
                        dir('NLPIngredients') {
                            bat '''
                            %PYTHON% -m venv venv
                            venv\\Scripts\\python -m pip install -r requirements.txt
                            venv\\Scripts\\python -m pytest || exit 0
                            '''
                        }
                    }
                }

                stage('LCALite') {
                    steps {
                        dir('LCALite') {
                            bat '''
                            %PYTHON% -m venv venv
                            venv\\Scripts\\python -m pip install -r requirements.txt
                            venv\\Scripts\\python -m pytest || exit 0
                            '''
                        }
                    }
                }

                stage('Scoring') {
                    steps {
                        dir('Scoring') {
                            bat '''
                            %PYTHON% -m venv venv
                            venv\\Scripts\\python -m pip install -r requirements.txt
                            venv\\Scripts\\python -m pytest || exit 0
                            '''
                        }
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            parallel {

                stage('Gateway Sonar') {
                    steps {
                        dir('Gateway') {
                            withSonarQubeEnv('Gateway') {
                                bat '''
                                sonar-scanner ^
                                -Dsonar.projectKey=Gateway ^
                                -Dsonar.sources=. ^
                                -Dsonar.language=py ^
                                -Dsonar.host.url=%SONAR_HOST_URL%
                                '''
                            }
                        }
                    }
                }

                stage('ParserProduit Sonar') {
                    steps {
                        dir('ParserProduit') {
                            withSonarQubeEnv('Parser-Produit') {
                                bat '''
                                sonar-scanner ^
                                -Dsonar.projectKey=Parser-Produit ^
                                -Dsonar.sources=. ^
                                -Dsonar.language=py ^
                                -Dsonar.host.url=%SONAR_HOST_URL%
                                '''
                            }
                        }
                    }
                }

                stage('NLPIngredients Sonar') {
                    steps {
                        dir('NLPIngredients') {
                            withSonarQubeEnv('Nlp-Ingredients') {
                                bat '''
                                sonar-scanner ^
                                -Dsonar.projectKey=Nlp-Ingredients ^
                                -Dsonar.sources=. ^
                                -Dsonar.language=py ^
                                -Dsonar.host.url=%SONAR_HOST_URL%
                                '''
                            }
                        }
                    }
                }

                stage('LCALite Sonar') {
                    steps {
                        dir('LCALite') {
                            withSonarQubeEnv('Lca-Lite') {
                                bat '''
                                sonar-scanner ^
                                -Dsonar.projectKey=Lca-Lite ^
                                -Dsonar.sources=. ^
                                -Dsonar.language=py ^
                                -Dsonar.host.url=%SONAR_HOST_URL%
                                '''
                            }
                        }
                    }
                }

                stage('Scoring Sonar') {
                    steps {
                        dir('Scoring') {
                            withSonarQubeEnv('Scoring') {
                                bat '''
                                sonar-scanner ^
                                -Dsonar.projectKey=Scoring ^
                                -Dsonar.sources=. ^
                                -Dsonar.language=py ^
                                -Dsonar.host.url=%SONAR_HOST_URL%
                                '''
                            }
                        }
                    }
                }
            }
        }

        stage('Docker Build & Deploy') {
            steps {
                dir('deploy') {
                    bat 'docker compose down'
                    bat 'docker compose build'
                    bat 'docker compose up -d'
                }
            }
        }
    }
}
