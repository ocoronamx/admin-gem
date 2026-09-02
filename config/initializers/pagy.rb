# Pagy 43 redujo los requisitos de configuración ~99% según su propio
# changelog — no hace falta requerir "extras" como en versiones viejas.
# Solo fijamos lo único que sí queremos decidir nosotros: filas por página.
Pagy::OPTIONS[:limit] = 20
