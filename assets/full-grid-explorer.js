(function () {
  "use strict";

  var root = document.getElementById("clt-explorer");
  if (!root) return;

  var dataUrl = root.getAttribute("data-url") || "assets/full-grid-visuals.json";
  var populationSelect = document.getElementById("clt-population");
  var graphSelect = document.getElementById("clt-graph");
  var nSlider = document.getElementById("clt-n");
  var nOutput = document.getElementById("clt-n-output");
  var statusBadge = document.getElementById("clt-status");
  var stableText = document.getElementById("clt-stable");
  var description = document.getElementById("clt-description");
  var metricStrip = document.getElementById("clt-metrics");
  var svg = document.getElementById("clt-plot");
  var loading = document.getElementById("clt-loading");
  var error = document.getElementById("clt-error");
  var populationMap = {};
  var populations = [];
  var currentData = null;

  var SVG_NS = "http://www.w3.org/2000/svg";
  var colors = {
    navy: "#102a43",
    slate: "#52606d",
    teal: "#0f766e",
    aqua: "#c9f0eb",
    blue: "#2f6fed",
    orange: "#d97706",
    red: "#c0392b",
    grid: "#d9e2ec",
    gray: "#e8edf2",
    white: "#ffffff"
  };

  function svgNode(name, attrs) {
    var node = document.createElementNS(SVG_NS, name);
    Object.keys(attrs || {}).forEach(function (key) {
      node.setAttribute(key, attrs[key]);
    });
    return node;
  }

  function appendText(parent, x, y, value, attrs) {
    var node = svgNode("text", Object.assign({ x: x, y: y }, attrs || {}));
    node.textContent = value;
    parent.appendChild(node);
    return node;
  }

  function clearSvg() {
    while (svg.firstChild) svg.removeChild(svg.firstChild);
  }

  function formatNumber(value, digits) {
    if (value === null || value === undefined || !isFinite(value)) return "NA";
    return Number(value).toFixed(digits === undefined ? 3 : digits);
  }

  function formatSigned(value, digits) {
    if (value === null || value === undefined || !isFinite(value)) return "NA";
    return (value >= 0 ? "+" : "") + formatNumber(value, digits);
  }

  function scale(value, domainMin, domainMax, rangeMin, rangeMax) {
    if (domainMax === domainMin) return (rangeMin + rangeMax) / 2;
    return rangeMin + ((value - domainMin) / (domainMax - domainMin)) *
      (rangeMax - rangeMin);
  }

  function drawFrame(title, subtitle) {
    clearSvg();
    svg.setAttribute("viewBox", "0 0 960 520");
    appendText(svg, 70, 32, title, {
      fill: colors.navy,
      "font-size": 22,
      "font-weight": 750
    });
    appendText(svg, 70, 52, subtitle, {
      fill: colors.slate,
      "font-size": 13
    });
  }

  function drawGrid(x0, x1, y0, y1, ticks, xScale, yScale) {
    ticks.forEach(function (tick) {
      var x = xScale(tick);
      svg.appendChild(svgNode("line", {
        x1: x, x2: x, y1: y0, y2: y1,
        stroke: colors.grid, "stroke-width": 1
      }));
    });
  }

  function drawAxes(x0, x1, y0, y1, xTicks, yTicks, xScale, yScale,
                   xLabel, yLabel, xFormatter, yFormatter) {
    svg.appendChild(svgNode("line", {
      x1: x0, x2: x1, y1: y1, y2: y1,
      stroke: colors.slate, "stroke-width": 1.2
    }));
    svg.appendChild(svgNode("line", {
      x1: x0, x2: x0, y1: y0, y2: y1,
      stroke: colors.slate, "stroke-width": 1.2
    }));
    xTicks.forEach(function (tick) {
      var x = xScale(tick);
      svg.appendChild(svgNode("line", {
        x1: x, x2: x, y1: y1, y2: y1 + 5,
        stroke: colors.slate
      }));
      appendText(svg, x, y1 + 23, xFormatter(tick), {
        fill: colors.slate, "font-size": 12, "text-anchor": "middle"
      });
    });
    yTicks.forEach(function (tick) {
      var y = yScale(tick);
      svg.appendChild(svgNode("line", {
        x1: x0 - 5, x2: x0, y1: y, y2: y,
        stroke: colors.slate
      }));
      appendText(svg, x0 - 10, y + 4, yFormatter(tick), {
        fill: colors.slate, "font-size": 12, "text-anchor": "end"
      });
    });
    appendText(svg, (x0 + x1) / 2, y1 + 52, xLabel, {
      fill: colors.slate, "font-size": 13, "text-anchor": "middle"
    });
    var label = appendText(svg, 20, (y0 + y1) / 2, yLabel, {
      fill: colors.slate, "font-size": 13, "text-anchor": "middle"
    });
    label.setAttribute("transform",
      "rotate(-90 20 " + ((y0 + y1) / 2) + ")");
  }

  function renderHistogram(population, entry) {
    var h = entry.histogram;
    var d = entry.diagnostics;
    drawFrame(
      "Sampling distribution of the sample mean",
      population.label + "  ·  n = " + entry.n + "  ·  B = 10,000"
    );

    var x0 = 82, x1 = 925, y0 = 78, y1 = 430;
    var xScale = function (v) { return scale(v, h.lower, h.upper, x0, x1); };
    var maxCount = Math.max.apply(null, h.counts);
    var yScale = function (v) { return scale(v, 0, maxCount, y1, y0); };
    var xTicks = [h.lower, h.lower + (h.upper - h.lower) * 0.25,
      h.lower + (h.upper - h.lower) * 0.5,
      h.lower + (h.upper - h.lower) * 0.75, h.upper];
    var yTicks = [0, maxCount * 0.25, maxCount * 0.5,
      maxCount * 0.75, maxCount];

    drawGrid(x0, x1, y0, y1, xTicks, xScale, function () {});
    h.counts.forEach(function (count, i) {
      var width = (x1 - x0) / h.counts.length;
      var center = h.centers[i];
      var bar = svgNode("rect", {
        x: xScale(center) - width / 2 + 1,
        y: yScale(count),
        width: Math.max(1, width - 2),
        height: y1 - yScale(count),
        rx: 2,
        fill: colors.teal,
        opacity: 0.82
      });
      svg.appendChild(bar);
    });
    drawAxes(x0, x1, y0, y1, xTicks, yTicks, xScale, yScale,
      "Sample mean", "Number of simulated means",
      function (v) { return formatNumber(v, 2); },
      function (v) { return Math.round(v).toString(); });

    var meanX = xScale(d.simulated_mean);
    svg.appendChild(svgNode("line", {
      x1: meanX, x2: meanX, y1: y0, y2: y1,
      stroke: colors.orange, "stroke-width": 2, "stroke-dasharray": "6 5"
    }));
    appendText(svg, Math.min(meanX + 8, x1 - 100), y0 + 18,
      "simulated mean = " + formatNumber(d.simulated_mean, 3), {
        fill: colors.orange, "font-size": 12, "font-weight": 700
      });
  }

  function renderQQ(population, entry) {
    var q = entry.qq;
    drawFrame(
      "Normal Q-Q plot",
      population.label + "  ·  n = " + entry.n +
      "  ·  standardized sample-mean quantiles"
    );

    var x0 = 82, x1 = 925, y0 = 78, y1 = 430;
    var lower = Math.min.apply(null, q.theoretical.concat(q.observed));
    var upper = Math.max.apply(null, q.theoretical.concat(q.observed));
    var padding = (upper - lower) * 0.08;
    lower -= padding;
    upper += padding;
    var xScale = function (v) { return scale(v, lower, upper, x0, x1); };
    var yScale = function (v) { return scale(v, lower, upper, y1, y0); };
    var ticks = [-2, -1, 0, 1, 2].filter(function (v) {
      return v >= lower && v <= upper;
    });
    drawGrid(x0, x1, y0, y1, ticks, xScale, function () {});
    svg.appendChild(svgNode("line", {
      x1: xScale(lower), y1: yScale(lower),
      x2: xScale(upper), y2: yScale(upper),
      stroke: colors.orange, "stroke-width": 1.8, "stroke-dasharray": "6 5"
    }));
    q.theoretical.forEach(function (value, i) {
      svg.appendChild(svgNode("circle", {
        cx: xScale(value),
        cy: yScale(q.observed[i]),
        r: 4.2,
        fill: colors.teal,
        opacity: 0.82
      }));
    });
    drawAxes(x0, x1, y0, y1, ticks, ticks, xScale, yScale,
      "Theoretical normal quantiles", "Observed standardized quantiles",
      function (v) { return formatNumber(v, 1); },
      function (v) { return formatNumber(v, 1); });
    appendText(svg, x1 - 4, y0 + 18,
      "dashed line = ideal normal agreement", {
        fill: colors.orange, "font-size": 12, "text-anchor": "end"
      });
  }

  function renderDiagnostics(population, entry) {
    var d = entry.diagnostics;
    var criteria = currentData.metadata.criteria;
    var metrics = [
      { label: "|skewness|", value: Math.abs(d.skewness),
        limit: criteria.abs_skewness_max, display: formatSigned(d.skewness, 3) },
      { label: "|excess kurtosis|", value: Math.abs(d.excess_kurtosis),
        limit: criteria.abs_excess_kurtosis_max,
        display: formatSigned(d.excess_kurtosis, 3) },
      { label: "Q-Q correlation", value: criteria.qq_correlation_min / d.qq_correlation,
        limit: 1, display: formatNumber(d.qq_correlation, 4) },
      { label: "Q-Q RMSE", value: d.qq_rmse,
        limit: criteria.qq_rmse_max, display: formatNumber(d.qq_rmse, 3) }
    ];
    drawFrame(
      "Normality diagnostic screen",
      population.label + "  ·  n = " + entry.n +
      "  ·  each bar is scaled to its criterion limit"
    );

    var x0 = 270, x1 = 890, yStart = 126, rowGap = 72;
    var maxRatio = Math.max.apply(null, metrics.map(function (m) {
      return Math.max(1.15, m.value / m.limit);
    }));
    metrics.forEach(function (metric, i) {
      var y = yStart + i * rowGap;
      var ratio = metric.value / metric.limit;
      var barEnd = x0 + (x1 - x0) * Math.min(ratio / maxRatio, 1);
      var pass = ratio <= 1;
      appendText(svg, 82, y + 6, metric.label, {
        fill: colors.navy, "font-size": 15, "font-weight": 700
      });
      appendText(svg, 82, y + 27, "observed = " + metric.display +
        "  ·  limit = " + formatNumber(metric.limit, 3), {
        fill: colors.slate, "font-size": 12
      });
      svg.appendChild(svgNode("rect", {
        x: x0, y: y - 13, width: x1 - x0, height: 22, rx: 7,
        fill: colors.gray
      }));
      svg.appendChild(svgNode("rect", {
        x: x0, y: y - 13, width: Math.max(3, barEnd - x0),
        height: 22, rx: 7, fill: pass ? colors.teal : colors.red,
        opacity: 0.88
      }));
      var thresholdX = x0 + (x1 - x0) / maxRatio;
      svg.appendChild(svgNode("line", {
        x1: thresholdX, x2: thresholdX, y1: y - 18, y2: y + 12,
        stroke: colors.orange, "stroke-width": 2
      }));
      appendText(svg, x1 + 10, y + 5, pass ? "PASS" : "FAIL", {
        fill: pass ? colors.teal : colors.red,
        "font-size": 12, "font-weight": 800
      });
    });
    appendText(svg, x0, 430,
      "Orange marker = criterion boundary  ·  values at or left of marker pass", {
        fill: colors.slate, "font-size": 12
      });
  }

  function renderComparison(entry) {
    drawFrame(
      "Which populations pass at this sample size?",
      "Exact integer n = " + entry.n + "  ·  green = all four criteria pass"
    );
    var x0 = 350, x1 = 900, y0 = 84, rowGap = 34;
    var all = populations.map(function (population) {
      return {
        population: population,
        entry: population.by_n[String(entry.n)]
      };
    });
    all.forEach(function (item, i) {
      var y = y0 + i * rowGap;
      var pass = item.entry.normal_enough;
      appendText(svg, 70, y + 5, item.population.label, {
        fill: colors.navy, "font-size": 13
      });
      svg.appendChild(svgNode("rect", {
        x: x0, y: y - 12, width: 330, height: 20, rx: 7,
        fill: pass ? colors.aqua : colors.gray
      }));
      appendText(svg, x0 + 165, y + 3, pass ? "PASS" : "FAIL", {
        fill: pass ? colors.teal : colors.slate,
        "font-size": 12, "font-weight": 800, "text-anchor": "middle"
      });
      appendText(svg, x1, y + 4,
        pass ? "all four criteria" : "at least one criterion fails", {
          fill: pass ? colors.teal : colors.slate, "font-size": 12
        });
    });
    appendText(svg, 70, y0 + all.length * rowGap + 20,
      "Use the population selector for distribution-specific graphs.", {
        fill: colors.slate, "font-size": 12
      });
  }

  function updateMetrics(population, entry) {
    var d = entry.diagnostics;
    var items = [
      ["Skewness", formatSigned(d.skewness, 3)],
      ["Excess kurtosis", formatSigned(d.excess_kurtosis, 3)],
      ["Q-Q correlation", formatNumber(d.qq_correlation, 4)],
      ["Q-Q RMSE", formatNumber(d.qq_rmse, 3)],
      ["Simulated SD", formatNumber(d.simulated_sd, 4)]
    ];
    metricStrip.innerHTML = items.map(function (item) {
      return "<div class=\"explorer-metric\"><span>" + item[0] +
        "</span><strong>" + item[1] + "</strong></div>";
    }).join("");
    var passText = entry.normal_enough
      ? "Passes all four criteria at this n."
      : "Fails at least one criterion at this n.";
    statusBadge.textContent = passText;
    statusBadge.className = entry.normal_enough
      ? "explorer-status pass" : "explorer-status fail";
    if (population.selected_n === null || population.selected_n === undefined ||
        !isFinite(population.selected_n)) {
      stableText.textContent = "No stable pass through n = " +
        currentData.metadata.n_max + ".";
    } else {
      stableText.textContent = "First stable pass: n = " + population.selected_n +
        " (three consecutive passing integers).";
    }
    description.textContent = population.description;
  }

  function render() {
    if (!currentData) return;
    var population = populationMap[populationSelect.value];
    var n = Number(nSlider.value);
    var entry = population.by_n[String(n)];
    currentData.selected = entry;
    nOutput.textContent = String(n);
    updateMetrics(population, entry);
    if (graphSelect.value === "histogram") renderHistogram(population, entry);
    if (graphSelect.value === "qq") renderQQ(population, entry);
    if (graphSelect.value === "diagnostics") renderDiagnostics(population, entry);
    if (graphSelect.value === "comparison") renderComparison(entry);
  }

  function initialize(data) {
    currentData = data;
    populations = Object.keys(data.populations).map(function (key) {
      return data.populations[key];
    });
    populations.forEach(function (population) {
      populationMap[population.id] = population;
      var option = document.createElement("option");
      option.value = population.id;
      option.textContent = population.label;
      populationSelect.appendChild(option);
    });
    populationSelect.value = "normal";
    graphSelect.value = "histogram";
    nSlider.min = data.metadata.n_min;
    nSlider.max = data.metadata.n_max;
    nSlider.value = 30;
    nOutput.textContent = "30";
    loading.hidden = true;
    render();
  }

  populationSelect.addEventListener("change", render);
  graphSelect.addEventListener("change", render);
  nSlider.addEventListener("input", render);

  fetch(dataUrl)
    .then(function (response) {
      if (!response.ok) throw new Error("Could not load interactive data.");
      return response.json();
    })
    .then(initialize)
    .catch(function (loadError) {
      loading.hidden = true;
      error.hidden = false;
      error.textContent = "The interactive evidence could not load. " +
        loadError.message;
    });
}());

