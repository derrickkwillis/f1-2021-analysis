import pandas as pd
import numpy as np
import matplotlib
matplotlib.use("Agg")  
import matplotlib.pyplot as plt
import os


df = pd.read_csv("query_results/pace_per_race.csv")

# Visualizations of temmate comparisons over the season

race_order = {
    "Bahrain Grand Prix": 1,
    "Emilia Romagna Grand Prix": 2,
    "Portuguese Grand Prix": 3,
    "Spanish Grand Prix": 4,
    "Monaco Grand Prix": 5,
    "Azerbaijan Grand Prix": 6,
    "French Grand Prix": 7,
    "Styrian Grand Prix": 8,
    "Austrian Grand Prix": 9,
    "British Grand Prix": 10,
    "Hungarian Grand Prix": 11,
    "Belgian Grand Prix": 12,
    "Dutch Grand Prix": 13,
    "Italian Grand Prix": 14,
    "Russian Grand Prix": 15,
    "Turkish Grand Prix": 16,
    "United States Grand Prix": 17,
    "Mexico City Grand Prix": 18,
    "São Paulo Grand Prix": 19,
    "Qatar Grand Prix": 20,
    "Saudi Arabian Grand Prix": 21,
    "Abu Dhabi Grand Prix": 22
}

df["race_order"] = df["race"].map(race_order)

pairs = df[["driver1_name", "driver2_name"]].drop_duplicates()
os.makedirs("visuals/season_pairs/consistency", exist_ok=True)

for _, row in pairs.iterrows():
    d1 = row["driver1_name"]
    d2 = row["driver2_name"]

    pair_df = df[
        (df["driver1_name"] == d1) &
        (df["driver2_name"] == d2)
    ].copy()

    if pair_df.shape[0] < 5:
        continue

    pair_df = pair_df.sort_values("race_order")

    # ➕ Compute CV difference per race
    pair_df["cv_diff"] = (
        pair_df["driver2_lap_cv"] - pair_df["driver1_lap_cv"]
    )

    # Dynamic y-axis scaling
    y_values = pd.concat([
        pair_df["driver1_lap_cv"],
        pair_df["driver2_lap_cv"]
    ])

    y_min = y_values.min()
    y_max = y_values.max()
    padding = (y_max - y_min) * 0.15

    plt.figure(figsize=(10, 5))

    plt.plot(pair_df["race"], pair_df["driver1_lap_cv"], marker="o", label=d1)
    plt.plot(pair_df["race"], pair_df["driver2_lap_cv"], marker="o", label=d2)

    for _, r in pair_df.iterrows():
        y1 = r["driver1_lap_cv"]
        y2 = r["driver2_lap_cv"]

        plt.vlines(
            x=r["race"],
            ymin=min(y1, y2),
            ymax=max(y1, y2),
            linestyles="dotted",
            alpha=0.6
        )

        better_driver = d1 if y1 < y2 else d2
        y_text = max(y1, y2) + padding * 0.25

        plt.text(
            r["race"],
            y_text,
            f"{abs(r['cv_diff']):.3f}\n{better_driver}",
            ha="center",
            va="bottom",
            fontsize=8
        )

    plt.ylim(max(0, y_min - padding), y_max + padding)

    plt.ylabel("Lap Coefficient of Variation (CV)")
    plt.xlabel("Race")
    plt.title(
        f"Lap Consistency Comparison (CV) — {d1} vs {d2}\n"
        "Annotations show CV difference and more consistent driver"
    )

    plt.xticks(rotation=45)
    plt.legend()
    plt.tight_layout()

    filename = f"visuals/season_pairs/consistency/{d1}_vs_{d2}_season_consistency.png"
    plt.savefig(filename, dpi=300)
    plt.close()
