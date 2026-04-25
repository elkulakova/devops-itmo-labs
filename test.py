from app import *

def test_mul():
    assert np.all(matrix_mul([[1, 0], [0, 1]], [1, 2]) == np.array([1, 2])), "[[1, 0], [0, 1]] * [1, 2] should equal [1, 2]"
    assert np.all(matrix_mul([[1, 0], [0, 1]], [[4, 1], [2, 2]]) == np.array([[4, 1], [2, 2]])), "[[1, 0], [0, 1]] * [[4, 1], [2, 2]] should equal [[4, 1], [2, 2]]"
    print("All tests passed!")

if __name__ == "__main__":
    test_mul()