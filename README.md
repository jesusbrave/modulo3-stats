# Módulo 3 - Servicio de Estadísticas


## Descripción
Lambda `GET /stats/{codigo}` que devuelve estadísticas por día para un `codigo` dado.


## Variables importantes
- DDB_TABLE_STATS: nombre de la tabla DynamoDB (variable de Terraform y env var para la Lambda)


## Endpoints
- `GET https://<api_endpoint>/stats/{codigo}`
- Query params opcionales: `start_date=YYYY-MM-DD`, `end_date=YYYY-MM-DD`


## Ejemplo curl