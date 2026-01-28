#!/bin/bash
# Script de compilation de Core Lightning master avec support testnet4

set -e  # Arrêter en cas d'erreur

echo "========================================="
echo "Compilation de Core Lightning master"
echo "avec support testnet4"
echo "========================================="
echo ""

cd ~/lightning

# Ajouter Poetry au PATH
export PATH="$HOME/.local/bin:$PATH"

# Vérifier Poetry
echo "Vérification de Poetry..."
if ! command -v poetry &> /dev/null; then
    echo "❌ Poetry non trouvé"
    exit 1
fi
echo "✓ Poetry version: $(poetry --version)"

# Installer les dépendances Python
echo ""
echo "Installation des dépendances Python..."
poetry install --no-interaction

# Configurer
echo ""
echo "Configuration..."
./configure --enable-developer

# Compiler
echo ""
echo "Compilation (cela peut prendre 5-10 minutes)..."
poetry run make -j$(nproc)

# Vérifier
echo ""
echo "========================================="
echo "✓ Compilation terminée!"
echo "========================================="
echo ""

if [ -f lightningd/lightningd ]; then
    echo "✓ lightningd compilé avec succès"
    ./lightningd/lightningd --version
else
    echo "❌ lightningd introuvable"
    exit 1
fi

echo ""
echo "Installation..."
sudo make install

echo ""
echo "========================================="
echo "✓ Core Lightning installé!"
echo "========================================="
echo ""
echo "Version installée:"
lightningd --version

echo ""
echo "Test du support testnet4:"
lightningd --help | grep -i testnet4 && echo "✓ testnet4 supporté!" || echo "❌ testnet4 non trouvé"
