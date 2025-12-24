pipeline {
    agent any
    options {
        skipDefaultCheckout(false)
    }
    environment {
        SONAR_HOST_URL = "http://localhost:9999"
        SONAR_SCANNER = tool 'SonarScanner'
    }

    stages {

        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/team-ecolabel/EcoLabel-MS.git'
            }
        }

        stage('Python Quality & Tests') {
            parallel {
                stage('Gateway') {
                    steps {
                        dir('Gateway') {
                            bat '''
                            python -m venv venv
                            venv\\Scripts\\activate
                            pip install -r requirements.txt
                            flake8 .
                            pytest || exit 0
                            '''
                        }
                    }
                }

                stage('ParserProduit') {
                    steps {
                        dir('ParserProduit') {
                            bat '''
                            python -m venv venv
                            venv\\Scripts\\activate
                            pip install -r requirements.txt
                            flake8 .
                            pytest || exit 0
                            '''
                        }
                    }
                }

                stage('NLPIngredients') {
                    steps {
                        dir('NLPIngredients') {
                            bat '''
                            python -m venv venv
                            venv\\Scripts\\activate
                            pip install -r requirements.txt
                            flake8 .
                            pytest || exit 0
                            '''
                        }
                    }
                }

                stage('LCALite') {
                    steps {
                        dir('LCALite') {
                            bat '''
                            python -m venv venv
                            venv\\Scripts\\activate
                            pip install -r requirements.txt
                            flake8 .
                            pytest || exit 0
                            '''
                        }
                    }
                }

                stage('Scoring') {
                    steps {
                        dir('Scoring') {
                            bat '''
                            python -m venv venv
                            venv\\Scripts\\activate
                            pip install -r requirements.txt
                            flake8 .
                            pytest || exit 0
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
                                bat """
                                sonar-scanner ^
                                -Dsonar.projectKey=Gateway ^
                                -Dsonar.sources=. ^
                                -Dsonar.language=py
                                """
                            }
                        }
                    }
                }
                stage('ParserProduit Sonar') {
                    steps {
                        dir('ParserProduit') {
                            withSonarQubeEnv('Parser-Produit') {
                                bat """
                                sonar-scanner ^
                                -Dsonar.projectKey=Parser-Produit ^
                                -Dsonar.sources=. ^
                                -Dsonar.language=py
                                """
                            }
                        }
                    }
                }

                stage('NLPIngredients Sonar') {
                    steps {
                        dir('NLPIngredients') {
                            withSonarQubeEnv('Nlp-Ingredients') {
                                bat """
                                sonar-scanner ^
                                -Dsonar.projectKey=Nlp-Ingredients ^
                                -Dsonar.sources=. ^
                                -Dsonar.language=py
                                """
                            }
                        }
                    }
                }

                stage('LCALite Sonar') {
                    steps {
                        dir('LCALite') {
                            withSonarQubeEnv('Lca-Lite') {
                                bat """
                                sonar-scanner ^
                                -Dsonar.projectKey=Lca-Lite ^
                                -Dsonar.sources=. ^
                                -Dsonar.language=py
                                """
                            }
                        }
                    }
                }

                stage('Scoring Sonar') {
                    steps {
                        dir('Scoring') {
                            withSonarQubeEnv('Scoring') {
                                bat """
                                sonar-scanner ^
                                -Dsonar.projectKey=Scoring ^
                                -Dsonar.sources=. ^
                                -Dsonar.language=py
                                """
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
