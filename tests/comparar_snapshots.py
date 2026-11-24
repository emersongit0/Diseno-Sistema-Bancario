"""Compara los snapshots locales sin conectarse a Oracle ni leer tablas."""

from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]


def normalizar(texto: str) -> str:
    """Normaliza espacios, líneas vacías y finales de línea."""
    return "\n".join(" ".join(linea.split()) for linea in texto.splitlines() if linea.strip())


def comparar(antes: Path, despues: Path) -> tuple[int, str]:
    """Devuelve código de salida y diagnóstico sin mostrar el contenido."""
    try:
        inicial = normalizar(antes.read_text(encoding="utf-8-sig"))
        final = normalizar(despues.read_text(encoding="utf-8-sig"))
    except (OSError, UnicodeError):
        return 2, "No se pudieron leer ambos snapshots UTF-8. Guarda las salidas en docs/snapshot_ad_antes.txt y docs/snapshot_ad_despues.txt."
    if not inicial or not final:
        return 2, "Snapshot vacío: guarda el total y la lista completa de nombres de 00b_snapshot_ad.sql."
    if inicial != final:
        return 1, "SNAPSHOTS DIFERENTES: revisa nombres, cantidad y que ambas salidas tengan el mismo formato."
    return 0, "SNAPSHOTS OK: ambos archivos son idénticos tras normalizar espacios y finales de línea. Solo compara nombres y cantidad; no verifica contenido de tablas."


def main() -> int:
    """Compara los dos archivos fijados por la especificación."""
    codigo, mensaje = comparar(RAIZ / "docs/snapshot_ad_antes.txt", RAIZ / "docs/snapshot_ad_despues.txt")
    print(mensaje)
    return codigo


if __name__ == "__main__":
    raise SystemExit(main())
