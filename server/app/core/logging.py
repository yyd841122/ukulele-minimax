"""日志配置"""
import logging
import sys


def setup_logging(debug: bool = False) -> None:
    """配置根日志"""
    level = logging.DEBUG if debug else logging.INFO

    # 避免重复添加 handler
    root = logging.getLogger()
    if root.handlers:
        return

    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(
        logging.Formatter(
            "%(asctime)s | %(levelname)-7s | %(name)s | %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )
    )
    root.addHandler(handler)
    root.setLevel(level)

    # 抑制过吵的第三方日志
    for noisy in ("httpx", "httpcore", "multipart"):
        logging.getLogger(noisy).setLevel(logging.WARNING)