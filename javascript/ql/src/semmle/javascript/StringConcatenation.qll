/**
 * Provides predicates for analyzing string concatenations and their operands.
 */
import javascript

module StringConcatenation {
  /** Gets a data flow node referring to the result of the given concatenation. */
  private DataFlow::Node getAssignAddResult(AssignAddExpr expr) {
    result = expr.flow()
    or
    exists (SsaExplicitDefinition def | def.getDef() = expr |
      result = DataFlow::valueNode(def.getVariable().getAUse()))
  }

  /** Gets the `n`th operand to the string concatenation defining `node`. */
  DataFlow::Node getOperand(DataFlow::Node node, int n) {
    exists (AddExpr add | node = add.flow() |
      n = 0 and result = add.getLeftOperand().flow()
      or
      n = 1 and result = add.getRightOperand().flow())
    or
    exists (TemplateLiteral template | node = template.flow() |
      result = template.getElement(n).flow() and
      not exists (TaggedTemplateExpr tag | template = tag.getTemplate()))
    or
    exists (AssignAddExpr assign | node = getAssignAddResult(assign) |
      n = 0 and result = assign.getLhs().flow()
      or
      n = 1 and result = assign.getRhs().flow())
    or
    exists (DataFlow::ArrayCreationNode array |
      node = array.getAMethodCall("join") and
      node.(DataFlow::MethodCallNode).getArgument(0).mayHaveStringValue("") and
      result = array.getElement(n))
  }

  /** Gets an operand to the string concatenation defining `node`. */
  DataFlow::Node getAnOperand(DataFlow::Node node) {
    result = getOperand(node, _)
  }

  /** Gets the number of operands to the given concatenation. */
  int getNumOperand(DataFlow::Node node) {
    result = strictcount(getAnOperand(node))
  }

  /** Gets the first operand to the string concatenation defining `node`. */
  DataFlow::Node getFirstOperand(DataFlow::Node node) {
    result = getOperand(node, 0)
  }

  /** Gets the last operand to the string concatenation defining `node`. */
  DataFlow::Node getLastOperand(DataFlow::Node node) {
    result = getOperand(node, getNumOperand(node) - 1)
  }
  
  /**
   * Holds if `src` flows to `dst` through the `n`th operand of the given concatenation operator.
   */
  predicate taintStep(DataFlow::Node src, DataFlow::Node dst, DataFlow::Node operator, int n) {
    src = getOperand(dst, n) and
    operator = dst
  }

  /**
   * Holds if there is a taint step from `src` to `dst` through string concatenation.
   */
  predicate taintStep(DataFlow::Node src, DataFlow::Node dst) {
    taintStep(src, dst, _, _)
  }
}
